ENV["FILENAME"] = "unit/test_ferret" # rake sets $0 to rake-test-loader

require_relative "./test_helper"

class TestFerret < TestBase
  def test_log
    log(foo: :bar)
    assert_equal logs, "app=ferret-dev.ferret-minitest xid=deadbeef foo=bar\n"
  end

  def test_true
    test(name: :true) { true }

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 status=0 measure=success
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 val=100 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 at=return val=X.Y measure=time
EOF
  end
end

class TestFerretBash < TestBase
  def test_bash_true
    test(name: :true, bash: "true")

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 status=0 measure=success
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 val=100 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 at=return val=X.Y measure=time
EOF
  end
end
