require "./spec_helper"

describe OAuth::DeviceFlow::Error do
  it "all errors descend from Base" do
    (OAuth::DeviceFlow::Error::AuthorizationPending <= OAuth::DeviceFlow::Error::Base).should be_true
    (OAuth::DeviceFlow::Error::SlowDown <= OAuth::DeviceFlow::Error::Base).should be_true
    (OAuth::DeviceFlow::Error::AccessDenied <= OAuth::DeviceFlow::Error::Base).should be_true
    (OAuth::DeviceFlow::Error::ExpiredToken <= OAuth::DeviceFlow::Error::Base).should be_true
    (OAuth::DeviceFlow::Error::InvalidClient <= OAuth::DeviceFlow::Error::Base).should be_true
    (OAuth::DeviceFlow::Error::InvalidGrant <= OAuth::DeviceFlow::Error::Base).should be_true
    (OAuth::DeviceFlow::Error::NotAuthenticated <= OAuth::DeviceFlow::Error::Base).should be_true
    (OAuth::DeviceFlow::Error::NetworkError <= OAuth::DeviceFlow::Error::Base).should be_true
  end

  it "Base descends from Exception" do
    (OAuth::DeviceFlow::Error::Base <= Exception).should be_true
  end
end
