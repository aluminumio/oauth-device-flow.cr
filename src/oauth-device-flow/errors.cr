module OAuth::DeviceFlow::Error
  class Base < Exception; end
  class AuthorizationPending < Base; end
  class SlowDown < Base; end
  class AccessDenied < Base; end
  class ExpiredToken < Base; end
  class InvalidClient < Base; end
  class InvalidGrant < Base; end
  class NotAuthenticated < Base; end
  class NetworkError < Base; end
end
