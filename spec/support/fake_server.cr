require "http/server"
require "json"

module OAuth::DeviceFlow::Spec
  class FakeServer
    getter port : Int32

    def initialize
      @responses = Hash(String, Array(Proc(HTTP::Server::Context, Nil))).new
      @server = HTTP::Server.new do |context|
        path = context.request.path
        handlers = @responses[path]?
        if handlers && !handlers.empty?
          handler = handlers.shift
          handler.call(context)
        else
          context.response.status_code = 404
          context.response.content_type = "application/json"
          context.response.print %({"error":"unscripted_path","path":#{path.to_json}})
        end
      end
      address = @server.bind_unused_port
      @port = address.port
      spawn { @server.listen }
    end

    def base_url : String
      "http://127.0.0.1:#{@port}"
    end

    def on(path : String, &block : HTTP::Server::Context ->)
      handlers = @responses[path] ||= [] of Proc(HTTP::Server::Context, Nil)
      handlers << block
    end

    def stop
      @server.close
    end

    def self.with(&block : FakeServer ->)
      server = new
      begin
        block.call(server)
      ensure
        server.stop
      end
    end
  end
end
