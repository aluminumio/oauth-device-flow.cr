require "./spec_helper"
require "./support/fake_server"

describe "OAuth::DeviceFlow::Client#access_token" do
  it "returns the stored token when not expired" do
    store = OAuth::DeviceFlow::MemoryStore.new
    store.save(OAuth::DeviceFlow::Token.new(
      access_token: "AT",
      expires_at: Time.utc + 1.hour,
    ))
    client = OAuth::DeviceFlow::Client.new(
      base_url: "http://nowhere.invalid",
      client_id: "cli",
      store: store,
    )
    client.access_token.should eq("AT")
  end

  it "auto-refreshes when expired" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 200
        ctx.response.content_type = "application/json"
        ctx.response.print %({"access_token":"FRESH","expires_in":3600})
      end

      store = OAuth::DeviceFlow::MemoryStore.new
      store.save(OAuth::DeviceFlow::Token.new(
        access_token: "STALE",
        expires_at: Time.utc - 1.minute,
        refresh_token: "RT",
      ))

      client = OAuth::DeviceFlow::Client.new(
        base_url: server.base_url,
        client_id: "cli",
        store: store,
      )
      client.access_token.should eq("FRESH")
    end
  end

  it "raises NotAuthenticated when store is empty" do
    client = OAuth::DeviceFlow::Client.new(
      base_url: "http://nowhere.invalid",
      client_id: "cli",
      store: OAuth::DeviceFlow::MemoryStore.new,
    )
    expect_raises(OAuth::DeviceFlow::Error::NotAuthenticated) do
      client.access_token
    end
  end
end

describe "OAuth::DeviceFlow::Client#authenticated?" do
  it "returns false when store is empty" do
    OAuth::DeviceFlow::Client.new(
      base_url: "x", client_id: "y", store: OAuth::DeviceFlow::MemoryStore.new,
    ).authenticated?.should be_false
  end

  it "returns true when store has a token" do
    store = OAuth::DeviceFlow::MemoryStore.new
    store.save(OAuth::DeviceFlow::Token.new(access_token: "x", expires_at: Time.utc + 1.hour))
    OAuth::DeviceFlow::Client.new(
      base_url: "x", client_id: "y", store: store,
    ).authenticated?.should be_true
  end
end

describe "OAuth::DeviceFlow::Client#logout" do
  it "clears the store" do
    store = OAuth::DeviceFlow::MemoryStore.new
    store.save(OAuth::DeviceFlow::Token.new(access_token: "x", expires_at: Time.utc + 1.hour))
    OAuth::DeviceFlow::Client.new(
      base_url: "x", client_id: "y", store: store,
    ).logout
    store.load.should be_nil
  end
end
