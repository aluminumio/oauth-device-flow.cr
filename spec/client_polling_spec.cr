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

describe "OAuth::DeviceFlow::Client#poll_for_token (backoff)" do
  it "retries on authorization_pending, returns when token arrives" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 400
        ctx.response.content_type = "application/json"
        ctx.response.print %({"error":"authorization_pending"})
      end
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 400
        ctx.response.content_type = "application/json"
        ctx.response.print %({"error":"authorization_pending"})
      end
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 200
        ctx.response.content_type = "application/json"
        ctx.response.print %({"access_token":"AT","expires_in":3600})
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
      client.poll_for_token(device).access_token.should eq("AT")
    end
  end

  it "increases interval on slow_down and continues" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 400
        ctx.response.content_type = "application/json"
        ctx.response.print %({"error":"slow_down"})
      end
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 200
        ctx.response.content_type = "application/json"
        ctx.response.print %({"access_token":"AT","expires_in":3600})
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
      client.poll_for_token(device).access_token.should eq("AT")
    end
  end
end

describe "OAuth::DeviceFlow::Client#poll_for_token (terminal errors)" do
  it "raises AccessDenied on access_denied error" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 400
        ctx.response.content_type = "application/json"
        ctx.response.print %({"error":"access_denied"})
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
      expect_raises(OAuth::DeviceFlow::Error::AccessDenied) do
        client.poll_for_token(device)
      end
    end
  end

  it "raises ExpiredToken on expired_token error from server" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 400
        ctx.response.content_type = "application/json"
        ctx.response.print %({"error":"expired_token"})
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
      expect_raises(OAuth::DeviceFlow::Error::ExpiredToken) do
        client.poll_for_token(device)
      end
    end
  end

  it "raises ExpiredToken when overall deadline elapses (negative expires_in)" do
    OAuth::DeviceFlow::Spec::FakeServer.with do |server|
      server.on("/oauth/token") do |ctx|
        ctx.response.status_code = 400
        ctx.response.content_type = "application/json"
        ctx.response.print %({"error":"authorization_pending"})
      end

      client = OAuth::DeviceFlow::Client.new(
        base_url: server.base_url,
        client_id: "cli",
        store: OAuth::DeviceFlow::MemoryStore.new,
      )
      device = OAuth::DeviceFlow::DeviceCode.new(
        device_code: "DC", user_code: "X",
        verification_uri: "http://example",
        expires_in: -1, interval: 0,
      )
      expect_raises(OAuth::DeviceFlow::Error::ExpiredToken) do
        client.poll_for_token(device)
      end
    end
  end
end
