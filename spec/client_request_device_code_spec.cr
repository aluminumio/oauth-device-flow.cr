require "./spec_helper"
require "./support/fake_server"

describe "OAuth::DeviceFlow::Client#request_device_code" do
  it "POSTs form-encoded body and parses the response" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      received_body = ""
      received_content_type = ""
      server.on("/oauth/authorize_device") do |ctx|
        received_body = ctx.request.body.try(&.gets_to_end) || ""
        received_content_type = ctx.request.headers["Content-Type"]? || ""
        ctx.response.status_code = 200
        ctx.response.content_type = "application/json"
        ctx.response.print %({
          "device_code": "DC",
          "user_code": "ABCD-EFGH",
          "verification_uri": "#{server.base_url}/device",
          "verification_uri_complete": "#{server.base_url}/device?user_code=ABCD-EFGH",
          "expires_in": 600,
          "interval": 5
        })
      end

      client = OAuth::DeviceFlow::Client.new(
        base_url: server.base_url,
        client_id: "cli-uid",
        store: OAuth::DeviceFlow::MemoryStore.new,
      )
      dc = client.request_device_code("documents:read documents:write")
      dc.device_code.should eq("DC")
      dc.user_code.should eq("ABCD-EFGH")
      dc.expires_in.should eq(600)
      dc.interval.should eq(5)
      dc.verification_uri_complete.not_nil!.should contain("user_code=ABCD-EFGH")

      received_content_type.should contain("application/x-www-form-urlencoded")
      received_body.should contain("client_id=cli-uid")
      received_body.should contain("scope=documents%3Aread+documents%3Awrite")
    end
  end

  it "raises InvalidClient on 401 invalid_client" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/oauth/authorize_device") do |ctx|
        ctx.response.status_code = 401
        ctx.response.content_type = "application/json"
        ctx.response.print %({"error":"invalid_client"})
      end

      client = OAuth::DeviceFlow::Client.new(
        base_url: server.base_url,
        client_id: "bad",
        store: OAuth::DeviceFlow::MemoryStore.new,
      )
      expect_raises(OAuth::DeviceFlow::Error::InvalidClient) do
        client.request_device_code("x")
      end
    end
  end
end
