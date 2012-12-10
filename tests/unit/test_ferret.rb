ENV["NAME"] = "unit/test_ferret"

require_relative "./test_helper"

class TestFerret < TestBase
  def test_log
    log(foo: :bar)
    assert_equal logs, "app=ferret-dev.ferret-minitest xid=deadbeef foo=bar\n"
  end

  def test_true
    assert true
  end
end
