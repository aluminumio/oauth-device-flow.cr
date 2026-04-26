require "http/client"
require "json"
require "uri"

module OAuth::DeviceFlow
  class Client
    def initialize(
      @base_url : String,
      @client_id : String,
      @store : Store,
      @authorize_path : String = "/oauth/authorize_device",
      @token_path : String = "/oauth/token",
      @open_browser : Bool = true,
      @output : IO = STDOUT,
    )
    end

    def request_device_code(scope : String) : DeviceCode
      response = post_form(@authorize_path, {"client_id" => @client_id, "scope" => scope})
      raise_on_error(response)
      data = JSON.parse(response.body)
      DeviceCode.new(
        device_code: data["device_code"].as_s,
        user_code: data["user_code"].as_s,
        verification_uri: data["verification_uri"].as_s,
        expires_in: data["expires_in"].as_i,
        interval: data["interval"]?.try(&.as_i) || 5,
        verification_uri_complete: data["verification_uri_complete"]?.try(&.as_s),
      )
    end

    def poll_for_token(device : DeviceCode) : Token
      interval = device.interval
      deadline = Time.utc + device.expires_in.seconds
      loop do
        sleep interval.seconds if interval > 0
        raise Error::ExpiredToken.new("device code expired") if Time.utc >= deadline
        response = post_form(@token_path, {
          "client_id"   => @client_id,
          "device_code" => device.device_code,
          "grant_type"  => "urn:ietf:params:oauth:grant-type:device_code",
        })
        if response.status_code == 200
          return build_token(response)
        end
        case parse_error(response)
        when "authorization_pending" then next
        when "slow_down"             then interval += 5
        when "access_denied"         then raise Error::AccessDenied.new("user denied")
        when "expired_token"         then raise Error::ExpiredToken.new("device code expired")
        when "invalid_client"        then raise Error::InvalidClient.new("invalid client_id")
        else                              raise Error::Base.new("unexpected: #{parse_error(response)}")
        end
      end
    end

    def refresh! : Token
      tok = @store.load
      raise Error::NotAuthenticated.new("no stored token to refresh") unless tok
      rt = tok.refresh_token
      raise Error::InvalidGrant.new("stored token has no refresh_token") unless rt
      response = post_form(@token_path, {
        "grant_type"    => "refresh_token",
        "refresh_token" => rt,
        "client_id"     => @client_id,
      })
      raise_on_refresh_error(response) unless response.status_code == 200
      new_token = build_token(response, fallback_refresh: rt)
      @store.save(new_token)
      new_token
    end

    def access_token : String
      tok = @store.load
      raise Error::NotAuthenticated.new("no stored token; call authenticate first") unless tok
      tok = refresh! if tok.expired?
      tok.access_token
    end

    def authenticated? : Bool
      !@store.load.nil?
    end

    def logout : Nil
      @store.clear
    end

    private def raise_on_refresh_error(response : HTTP::Client::Response) : Nil
      err = parse_error(response)
      case err
      when "invalid_grant"  then raise Error::InvalidGrant.new("refresh token rejected")
      when "invalid_client" then raise Error::InvalidClient.new("invalid client_id")
      else                       raise Error::Base.new("HTTP #{response.status_code}: #{err}")
      end
    end

    private def build_token(response : HTTP::Client::Response, fallback_refresh : String? = nil) : Token
      data = JSON.parse(response.body)
      Token.new(
        access_token: data["access_token"].as_s,
        expires_at: Time.utc + data["expires_in"].as_i.seconds,
        refresh_token: data["refresh_token"]?.try(&.as_s) || fallback_refresh,
        scope: data["scope"]?.try(&.as_s),
      )
    end

    private def post_form(path : String, params : Hash(String, String)) : HTTP::Client::Response
      body = URI::Params.encode(params)
      headers = HTTP::Headers{
        "Content-Type" => "application/x-www-form-urlencoded",
        "Accept"       => "application/json",
      }
      HTTP::Client.post("#{@base_url}#{path}", headers: headers, body: body)
    rescue ex : IO::Error | Socket::Error
      raise Error::NetworkError.new(ex.message)
    end

    private def raise_on_error(response : HTTP::Client::Response) : Nil
      return if response.status_code == 200
      err = parse_error(response)
      case err
      when "invalid_client" then raise Error::InvalidClient.new("invalid client_id")
      else                       raise Error::Base.new("HTTP #{response.status_code}: #{err}")
      end
    end

    private def parse_error(response : HTTP::Client::Response) : String
      JSON.parse(response.body)["error"]?.try(&.as_s) || "unknown_error"
    rescue
      "unknown_error"
    end
  end
end
