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
