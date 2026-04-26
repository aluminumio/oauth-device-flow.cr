require "./spec_helper"
require "./support/fake_server"

describe "OAuth::DeviceFlow::Client#refresh!" do
  it "POSTs grant_type=refresh_token and updates the store" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      received_body = ""
      server.on("/oauth/token") do |ctx|
        received_body = ctx.request.body.try(&.gets_to_end) || ""
        ctx.response.status_code = 200
        ctx.response.content_type = "application/json"
        ctx.response.print %({"access_token":"NEW","expires_in":3600,"refresh_token":"NEWRT"})
      end

      store = OAuth::DeviceFlow::MemoryStore.new
      store.save(OAuth::DeviceFlow::Token.new(
        access_token: "OLD",
        expires_at: Time.utc - 1.minute,
        refresh_token: "OLDRT",
      ))

      client = OAuth::DeviceFlow::Client.new(
        base_url: server.base_url,
        client_id: "cli",
        store: store,
      )
      tok = client.refresh!
      tok.access_token.should eq("NEW")
      tok.refresh_token.should eq("NEWRT")
      store.load.not_nil!.access_token.should eq("NEW")
      received_body.should contain("grant_type=refresh_token")
      received_body.should contain("refresh_token=OLDRT")
      received_body.should contain("client_id=cli")
    end
  end

  it "preserves the old refresh_token when server omits it" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 200
        ctx.response.content_type = "application/json"
        ctx.response.print %({"access_token":"NEW","expires_in":3600})
      end

      store = OAuth::DeviceFlow::MemoryStore.new
      store.save(OAuth::DeviceFlow::Token.new(
        access_token: "OLD",
        expires_at: Time.utc - 1.minute,
        refresh_token: "OLDRT",
      ))

      client = OAuth::DeviceFlow::Client.new(
        base_url: server.base_url,
        client_id: "cli",
        store: store,
      )
      tok = client.refresh!
      tok.refresh_token.should eq("OLDRT")
    end
  end

  it "raises NotAuthenticated when store is empty" do
    client = OAuth::DeviceFlow::Client.new(
      base_url: "http://nowhere.invalid",
      client_id: "cli",
      store: OAuth::DeviceFlow::MemoryStore.new,
    )
    expect_raises(OAuth::DeviceFlow::Error::NotAuthenticated) do
      client.refresh!
    end
  end

  it "raises InvalidGrant when the stored token has no refresh_token" do
    store = OAuth::DeviceFlow::MemoryStore.new
    store.save(OAuth::DeviceFlow::Token.new(access_token: "OLD", expires_at: Time.utc - 1.minute))

    client = OAuth::DeviceFlow::Client.new(
      base_url: "http://nowhere.invalid",
      client_id: "cli",
      store: store,
    )
    expect_raises(OAuth::DeviceFlow::Error::InvalidGrant) do
      client.refresh!
    end
  end
end
