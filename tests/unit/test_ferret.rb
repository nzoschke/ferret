require_relative "./test_helper"

class TestFerret < TestBase
  def test_bash_true
    bash(name: :true, stdin: <<-'EOF')
      true
    EOF
  end

  def test_true
    assert true
  end
end
