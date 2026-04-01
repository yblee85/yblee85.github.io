require_relative "../lib/web/response"
require_relative "../service/auth/user_role"

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

      if admin_api?(env) && !user_is_admin?(user)
        body = Web::Response.error(code: "unauthorized", message: "admin access required")
        return [401, { "Content-Type" => "application/json" }, [body.to_json]]
      end

      @app.call(env)
    end

    private

    def applies?(env)
      env["PATH_INFO"].to_s.start_with?(@prefix)
    end

    def admin_api?(env)
      admin_api_prefix = "#{@prefix}admin/"
      env["PATH_INFO"].to_s.start_with?(admin_api_prefix)
    end

    def user_is_admin?(user)
      roles = user["roles"] || user[:roles]
      Array(roles).include?(Auth::UserRole::ADMIN)
    end
  end
end
