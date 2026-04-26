module OAuth::DeviceFlow
  struct DeviceCode
    getter device_code : String
    getter user_code : String
    getter verification_uri : String
    getter verification_uri_complete : String?
    getter expires_in : Int32
    getter interval : Int32

    def initialize(
      @device_code : String,
      @user_code : String,
      @verification_uri : String,
      @expires_in : Int32,
      @interval : Int32,
      @verification_uri_complete : String? = nil,
    )
    end
  end
end

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
