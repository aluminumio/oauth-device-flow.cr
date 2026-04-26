require "./spec_helper"

describe OAuth::DeviceFlow::DeviceCode do
  it "stores all required fields" do
    dc = OAuth::DeviceFlow::DeviceCode.new(
      device_code: "dc",
      user_code: "ABCD-EFGH",
      verification_uri: "https://example.com/device",
      expires_in: 600,
      interval: 5,
    )
    dc.device_code.should eq("dc")
    dc.user_code.should eq("ABCD-EFGH")
    dc.verification_uri.should eq("https://example.com/device")
    dc.verification_uri_complete.should be_nil
    dc.expires_in.should eq(600)
    dc.interval.should eq(5)
  end

  it "accepts an optional verification_uri_complete" do
    dc = OAuth::DeviceFlow::DeviceCode.new(
      device_code: "dc",
      user_code: "X",
      verification_uri: "https://example.com/device",
      verification_uri_complete: "https://example.com/device?user_code=X",
      expires_in: 600,
      interval: 5,
    )
    dc.verification_uri_complete.should eq("https://example.com/device?user_code=X")
  end
end
