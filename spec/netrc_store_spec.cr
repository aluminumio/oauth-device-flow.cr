require "./spec_helper"

describe OAuth::DeviceFlow::NetrcStore do
  it "returns nil when the netrc file does not exist" do
    mktmpdir do |tmp|
      path = File.join(tmp, "netrc")
      store = OAuth::DeviceFlow::NetrcStore.new(machine: "example.com", path: path)
      store.load.should be_nil
    end
  end

  it "returns nil when the netrc file lacks a matching machine block" do
    mktmpdir do |tmp|
      path = File.join(tmp, "netrc")
      File.write(path, "machine other.com\n  login oauth\n  password tok\n")
      store = OAuth::DeviceFlow::NetrcStore.new(machine: "example.com", path: path)
      store.load.should be_nil
    end
  end

  it "round-trips a Token through save/load" do
    mktmpdir do |tmp|
      path = File.join(tmp, "netrc")
      store = OAuth::DeviceFlow::NetrcStore.new(machine: "example.com", path: path)
      expires = Time.utc(2026, 5, 1, 0, 0, 0)
      token = OAuth::DeviceFlow::Token.new(
        access_token: "AT",
        expires_at: expires,
        refresh_token: "RT",
        scope: "documents:read",
      )
      store.save(token)
      loaded = store.load.not_nil!
      loaded.access_token.should eq("AT")
      loaded.refresh_token.should eq("RT")
      loaded.expires_at.should eq(expires)
      loaded.scope.should eq("documents:read")
    end
  end

  it "preserves unrelated machine blocks on save" do
    mktmpdir do |tmp|
      path = File.join(tmp, "netrc")
      File.write(path, "machine other.com\n  login bob\n  password pw\n")
      store = OAuth::DeviceFlow::NetrcStore.new(machine: "example.com", path: path)
      store.save(OAuth::DeviceFlow::Token.new(access_token: "AT", expires_at: Time.utc + 1.hour))
      contents = File.read(path)
      contents.should contain("machine other.com")
      contents.should contain("machine example.com")
    end
  end

  it "replaces the existing entry on save" do
    mktmpdir do |tmp|
      path = File.join(tmp, "netrc")
      store = OAuth::DeviceFlow::NetrcStore.new(machine: "example.com", path: path)
      store.save(OAuth::DeviceFlow::Token.new(access_token: "old", expires_at: Time.utc + 1.hour))
      store.save(OAuth::DeviceFlow::Token.new(access_token: "new", expires_at: Time.utc + 1.hour))
      File.read(path).scan(/machine example\.com/).size.should eq(1)
      store.load.not_nil!.access_token.should eq("new")
    end
  end

  it "clear removes the entry but leaves other machines" do
    mktmpdir do |tmp|
      path = File.join(tmp, "netrc")
      store = OAuth::DeviceFlow::NetrcStore.new(machine: "example.com", path: path)
      store.save(OAuth::DeviceFlow::Token.new(access_token: "AT", expires_at: Time.utc + 1.hour))
      File.write(path, File.read(path) + "\nmachine other.com\n  login bob\n  password pw\n")
      store.clear
      contents = File.read(path)
      contents.should_not contain("machine example.com")
      contents.should contain("machine other.com")
    end
  end

  it "chmods the file to 0600 on save" do
    mktmpdir do |tmp|
      path = File.join(tmp, "netrc")
      store = OAuth::DeviceFlow::NetrcStore.new(machine: "example.com", path: path)
      store.save(OAuth::DeviceFlow::Token.new(access_token: "AT", expires_at: Time.utc + 1.hour))
      mode = File.info(path).permissions.value & 0o777
      mode.should eq(0o600)
    end
  end
end
