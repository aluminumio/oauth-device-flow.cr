require "./spec_helper"

describe OAuth::DeviceFlow::MemoryStore do
  it "returns nil from load when empty" do
    store = OAuth::DeviceFlow::MemoryStore.new
    store.load.should be_nil
  end

  it "round-trips a Token through save/load" do
    store = OAuth::DeviceFlow::MemoryStore.new
    token = OAuth::DeviceFlow::Token.new(
      access_token: "at",
      expires_at: Time.utc + 1.hour,
      refresh_token: "rt",
      scope: "x",
    )
    store.save(token)
    loaded = store.load.not_nil!
    loaded.access_token.should eq("at")
    loaded.refresh_token.should eq("rt")
    loaded.scope.should eq("x")
  end

  it "clear removes the stored token" do
    store = OAuth::DeviceFlow::MemoryStore.new
    store.save(OAuth::DeviceFlow::Token.new(access_token: "a", expires_at: Time.utc + 1.hour))
    store.clear
    store.load.should be_nil
  end

  it "is a Store" do
    (OAuth::DeviceFlow::MemoryStore <= OAuth::DeviceFlow::Store).should be_true
  end
end
