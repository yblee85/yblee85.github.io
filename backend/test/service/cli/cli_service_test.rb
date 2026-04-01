require_relative "../../test_helper"
require_relative "../../../src/service/cli/cli_service"

class CliServiceTest < Minitest::Test
  def test_run_returns_ok_true_for_success
    svc = Cli::Service.new
    result = svc.run("sh", "-c", "echo hi")

    assert_equal true, result.ok
    assert_equal 0, result.exit_code
    assert_includes result.stdout, "hi"
  end

  def test_run_returns_ok_false_for_failure
    svc = Cli::Service.new
    result = svc.run("sh", "-c", "echo boom 1>&2; exit 12")

    assert_equal false, result.ok
    assert_equal 12, result.exit_code
    assert_includes result.stderr, "boom"
  end

  def test_run_raises_when_command_missing
    svc = Cli::Service.new
    assert_raises(ArgumentError) { svc.run }
  end
end
