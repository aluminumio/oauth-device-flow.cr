require "../spec_helper"
require "./fake_server"
require "http/client"

describe OAuth::DeviceFlow::Spec::FakeServer do
  it "scripts per-call responses on a path" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/foo") do |ctx|
        ctx.response.status_code = 200
        ctx.response.print "first"
      end
      server.on("/foo") do |ctx|
        ctx.response.status_code = 200
        ctx.response.print "second"
      end

      HTTP::Client.get("#{server.base_url}/foo").body.should eq("first")
      HTTP::Client.get("#{server.base_url}/foo").body.should eq("second")
      HTTP::Client.get("#{server.base_url}/foo").status_code.should eq(404)
    end
  end
end
