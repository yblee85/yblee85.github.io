require_relative "../../lib/config"
require_relative "../../lib/web/response"

module Route
  module HomeRoute
    def self.registered(app)
      register_home(app)
      register_health(app)
    end

    def self.register_home(app)
      app.get "/" do
        Web::Response.success.to_json
      end
    end

    def self.register_health(app)
      app.get "/health" do
        Web::Response.success.to_json
      end
    end
  end
end
