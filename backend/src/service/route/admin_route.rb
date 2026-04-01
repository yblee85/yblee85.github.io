require_relative "../../lib/web/response"

module Route
  module AdminRoute
    def self.registered(app)
      register_admin(app)
    end

    def self.register_admin(app)
      app.post "/api/admin/reindex_db" do
        qa = app.settings.container.qa
        qa.reindex_db
        Web::Response.success.to_json
      end
    end
  end
end
