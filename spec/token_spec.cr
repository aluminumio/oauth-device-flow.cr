require "./spec_helper"

describe OAuth::DeviceFlow::Token do
  it "is not expired when expires_at is in the future" do
    t = OAuth::DeviceFlow::Token.new(
      access_token: "abc",
      expires_at: Time.utc + 5.minutes,
    )
    t.expired?.should be_false
  end

  it "is expired when expires_at is in the past" do
    t = OAuth::DeviceFlow::Token.new(
      access_token: "abc",
      expires_at: Time.utc - 1.second,
    )
    t.expired?.should be_true
  end

  it "is expired when within skew window of expires_at" do
    t = OAuth::DeviceFlow::Token.new(
      access_token: "abc",
      expires_at: Time.utc + 10.seconds,
    )
    t.expired?(skew: 30.seconds).should be_true
  end

  it "exposes refresh_token and scope" do
    t = OAuth::DeviceFlow::Token.new(
      access_token: "abc",
      expires_at: Time.utc + 1.hour,
      refresh_token: "rt",
      scope: "documents:read",
    )
    t.refresh_token.should eq("rt")
    t.scope.should eq("documents:read")
  end
end
