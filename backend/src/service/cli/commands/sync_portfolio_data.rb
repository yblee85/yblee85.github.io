require_relative "../cli_service"

module Cli
  module Commands
    class SyncPortfolioData
      def initialize(cli: Cli::Service.new, script_path: default_script_path)
        @cli = cli
        @script_path = script_path
      end

      def call
        backend_root = File.expand_path("..", File.dirname(@script_path))
        @cli.run("sh", @script_path, chdir: backend_root)
      end

      private

      def default_script_path
        File.expand_path("../../../../script/sync_portfolio_data.sh", __dir__)
      end
    end
  end
end
