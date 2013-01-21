ENV["SCRIPT"] = __FILE__

require_relative "./test_helper"

class TestFerret < TestBase
  def test_env
    assert_equal "ferret-minitest",                   ENV["APP"]
    assert_equal __FILE__,                            ENV["SCRIPT"]
    assert                                            ENV["FERRET_DIR"]
    assert_equal "ferret-dev",                        ENV["ORG"]
    assert_equal "ferret-minitest-unit-test-ferret",  ENV["TARGET_APP"]
    assert                                            ENV["TEMP_DIR"]
    assert_equal "deadbeef",                          ENV["XID"]
  end

  def test_log
    log(foo: :bar)
    assert_equal logs, "app=ferret-dev.ferret-minitest xid=deadbeef foo=bar\n"
  end

  def test_true
    r = test(name: :true) { true }

    assert_equal true, r
    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 status=0 measure=success
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 val=100 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 at=return val=X.Y measure=time
EOF
  end

  def test_false
    r = test(name: :false) { false }

    assert_equal 1, r
    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 status=1 measure=failure
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 val=0 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 at=return val=X.Y
EOF
  end
end