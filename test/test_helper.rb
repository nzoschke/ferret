require "minitest/autorun"
require "stringio"
require "tmpdir"

ENV["ORG"] = "ferret-test"
ENV["XID"] = "deadbeef"

$logdevs = [StringIO.new]

require_relative "../lib/ferret"

class TestBase < MiniTest::Unit::TestCase
  def setup
    ENV["TEMP_DIR"] = Dir.mktmpdir
    $logdevs[0].rewind
    $logdevs[0].truncate(0)
  end

  def logs
    $logdevs[0].rewind
    $logdevs[0].read.gsub(/val=[0-9.]+/, "val=X")
  end
end
