require "spec"
require "file_utils"
require "../src/oauth-device-flow"

def mktmpdir(&)
  path = File.join(Dir.tempdir, "spec_#{Random::Secure.hex(8)}")
  Dir.mkdir(path)
  begin
    yield path
  ensure
    FileUtils.rm_rf(path)
  end
end
