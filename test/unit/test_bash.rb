ENV["SCRIPT"] = __FILE__

require_relative "./test_helper"

class TestBash < TestBase
  def test_true
    test(name: :true, bash: "true")

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 status=0 measure=success
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 val=100 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 at=return val=X.Y measure=time
EOF
  end

  def test_false
    test(name: :false, bash: "false")

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 status=1 measure=failure
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 val=0 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 at=return val=X.Y
EOF
  end

  def test_retry
    test(retry: 2, name: :false, bash: "false")

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 status=1
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=0 at=return val=X.Y
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=1 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=1 status=1 measure=failure
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=1 val=0 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.false i=1 at=return val=X.Y
EOF
  end

  def test_status
    test(name: :nonzero, status: 128, bash: "exit 128")

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.nonzero i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.nonzero i=0 status=128 measure=success
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.nonzero i=0 val=100 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.nonzero i=0 at=return val=X.Y measure=time
EOF
  end

  def test_status_nil
    test(name: :nonzero, status: nil, bash: "exit 128")

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.nonzero i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.nonzero i=0 status=128 measure=success
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.nonzero i=0 val=100 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.nonzero i=0 at=return val=X.Y measure=time
EOF
  end

  def test_pattern_true
    test(name: :grep, pattern: /hi/, bash: "echo hi")

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 status=0 measure=success
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 val=100 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 at=return val=X.Y measure=time
EOF
  end

  def test_pattern_false
    test(name: :grep, pattern: /hi/, bash: "echo hello")

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 at=failure out='hello'
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 status=0 measure=failure
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 val=0 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 at=return val=X.Y
EOF
  end

  def test_pattern_status
    test(name: :grep, pattern: /hi/, status: nil, bash: <<-'EOF')
      echo hi
      exit 1
    EOF

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 status=1 measure=success
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 val=100 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.grep i=0 at=return val=X.Y measure=time
EOF
  end

  def test_timeout
    test(name: :timeout, timeout: 0.01, bash: "sleep 2")

    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.timeout i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.timeout at=timeout val=X.Y
EOF
  end
end
