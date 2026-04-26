require "./spec_helper"
require "./support/fake_server"

describe "OAuth::DeviceFlow::Client#poll_for_token (happy path)" do
  it "returns a Token on first 200 response" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 200
        ctx.response.content_type = "application/json"
        ctx.response.print %({
          "access_token": "AT",
          "refresh_token": "RT",
          "expires_in": 3600,
          "scope": "documents:read"
        })
      end

      client = OAuth::DeviceFlow::Client.new(
        base_url: server.base_url,
        client_id: "cli",
        store: OAuth::DeviceFlow::MemoryStore.new,
      )
      device = OAuth::DeviceFlow::DeviceCode.new(
        device_code: "DC", user_code: "X",
        verification_uri: "http://example",
        expires_in: 600, interval: 0,
      )
      token = client.poll_for_token(device)
      token.access_token.should eq("AT")
      token.refresh_token.should eq("RT")
      token.scope.should eq("documents:read")
      (token.expires_at > Time.utc + 50.minutes).should be_true
    end
  end
end
