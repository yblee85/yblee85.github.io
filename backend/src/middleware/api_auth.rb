require_relative "../lib/web/response"

module Middleware
  class ApiAuth
    def initialize(app, prefix: "/api/")
      @app = app
      @prefix = prefix
    end

    def call(env)
      return @app.call(env) unless applies?(env)

      session = env["rack.session"] || {}
      user = session[:user] || session["user"]
      user_id =
        if user.is_a?(Hash)
          (user["user_id"] || user[:user_id]).to_s
        else
          ""
        end

      if user_id.strip.empty?
        body = Web::Response.error(code: "unauthorized", message: "authentication required")
        return [401, { "Content-Type" => "application/json" }, [body.to_json]]
      end

      @app.call(env)
    end

    private

    def applies?(env)
      env["PATH_INFO"].to_s.start_with?(@prefix)
    end
  end
end
