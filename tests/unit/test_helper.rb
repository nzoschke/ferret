require "minitest/autorun"
require "stringio"
require "tmpdir"

ENV["APP"] = "ferret-minitest"
ENV["ORG"] = "ferret-dev"
ENV["XID"] = "deadbeef"

$logdevs = [StringIO.new]

require "ferret"

class TestBase < MiniTest::Unit::TestCase
  def setup
    ENV["TEMP_DIR"] = Dir.mktmpdir
    $logdevs[0].rewind
    $logdevs[0].truncate(0)
  end

  def logs
    $logdevs[0].rewind
    l = $logdevs[0].read
    l.gsub!(/val=([0-9]+)\.([0-9]+)/, "val=X.Y") # mask floating point values
    l.gsub!(/xid=([0-9a-f]{8})/, "xid=deadbeef")
  end
end
