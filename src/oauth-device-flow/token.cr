module OAuth::DeviceFlow
  struct Token
    getter access_token : String
    getter refresh_token : String?
    getter expires_at : Time
    getter scope : String?

    def initialize(
      @access_token : String,
      @expires_at : Time,
      @refresh_token : String? = nil,
      @scope : String? = nil,
    )
    end

    def expired?(skew : Time::Span = 30.seconds) : Bool
      Time.utc + skew >= @expires_at
    end
  end
end
