require_relative "../../../test_helper"
require_relative "../../../../src/service/cli/commands/sync_portfolio_data"

class SyncPortfolioDataTest < Minitest::Test
  class FakeCli
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = []
    end

    def run(*args, **kwargs)
      @calls << [args, kwargs]
      @result
    end
  end

  def test_calls_sync_script_in_backend_root
    fake_result = Cli::Service::Result.new(ok: true, exit_code: 0, stdout: "ok", stderr: "")
    fake_cli = FakeCli.new(fake_result)

    cmd = Cli::Commands::SyncPortfolioData.new(cli: fake_cli)
    result = cmd.call

    assert_same fake_result, result
    assert_equal 1, fake_cli.calls.length

    args, kwargs = fake_cli.calls.first
    assert_equal "sh", args[0]
    assert_match %r{/script/sync_portfolio_data\.sh\z}, args[1]
    assert_match %r{/backend\z}, kwargs.fetch(:chdir)
  end
end
