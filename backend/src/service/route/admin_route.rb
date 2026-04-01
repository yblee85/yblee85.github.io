require_relative "../../lib/web/response"
require_relative "../cli/commands/sync_portfolio_data"

module Route
  module AdminRoute
    def self.registered(app)
      register_admin(app)
    end

    def self.register_admin(app)
      app.post "/api/admin/reindex_db" do
        sync = Cli::Commands::SyncPortfolioData.new.call
        unless sync.ok
          halt 500, Web::Response.error(
            code: "sync_failed",
            message: "portfolio data sync failed",
            details: {
              exit_code: sync.exit_code,
              stderr: sync.stderr.to_s[0, 2000]
            }
          ).to_json
        end

        qa = app.settings.container.qa
        qa.reindex_db
        Web::Response.success(data: { synced: true, reindexed: true }).to_json
      end
    end
  end
end
