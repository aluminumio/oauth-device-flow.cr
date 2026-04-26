require "./spec_helper"
require "./support/fake_server"

describe "OAuth::DeviceFlow::Client#authenticate" do
  it "runs the full flow and persists the token" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/oauth/authorize_device") do |ctx|
        ctx.response.status_code = 200
        ctx.response.content_type = "application/json"
        ctx.response.print %({
          "device_code":"DC","user_code":"ABCD-EFGH",
          "verification_uri":"#{server.base_url}/device",
          "verification_uri_complete":"#{server.base_url}/device?user_code=ABCD-EFGH",
          "expires_in":600,"interval":0
        })
      end
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 200
        ctx.response.content_type = "application/json"
        ctx.response.print %({"access_token":"AT","refresh_token":"RT","expires_in":3600})
      end

      store = OAuth::DeviceFlow::MemoryStore.new
      output = IO::Memory.new
      client = OAuth::DeviceFlow::Client.new(
        base_url: server.base_url,
        client_id: "cli",
        store: store,
        open_browser: false,
        output: output,
      )
      tok = client.authenticate("documents:read")
      tok.access_token.should eq("AT")
      store.load.not_nil!.access_token.should eq("AT")
      output.to_s.should contain("ABCD-EFGH")
      output.to_s.should contain("/device?user_code=ABCD-EFGH")
    end
  end
end
