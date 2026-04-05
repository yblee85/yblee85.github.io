require "json"
require "rack/utils"
require_relative "../lib/web/response"
require_relative "../service/auth/csrf_token"

module Middleware
  class CsrfProtection
    def initialize(app, prefix: "/api/")
      @app = app
      @prefix = prefix
    end

    def call(env)
      return @app.call(env) unless applies?(env)

      method = env["REQUEST_METHOD"].to_s.upcase
      return @app.call(env) unless %w[POST PUT PATCH DELETE].include?(method)

      session = env["rack.session"] || {}
      user = session[:user] || session["user"]
      user_id =
        if user.is_a?(Hash)
          (user["user_id"] || user[:user_id]).to_s
        else
          ""
        end

      return @app.call(env) if user_id.strip.empty?

      expected = Auth::CsrfToken.read(session)
      if expected.empty?
        body = Web::Response.error(
          code: "csrf_invalid",
          message: "CSRF token not initialized; refresh with GET /auth/me"
        )
        return [403, { "Content-Type" => "application/json" }, [body.to_json]]
      end

      given = env["HTTP_X_CSRF_TOKEN"].to_s
      unless tokens_match?(given, expected)
        body = Web::Response.error(
          code: "csrf_invalid",
          message: "CSRF token missing or invalid"
        )
        return [403, { "Content-Type" => "application/json" }, [body.to_json]]
      end

      @app.call(env)
    end

    private

    def applies?(env)
      env["PATH_INFO"].to_s.start_with?(@prefix)
    end

    def tokens_match?(given, expected)
      return false if given.empty? || expected.empty?

      a = given.b
      b = expected.b
      return false unless a.bytesize == b.bytesize

      Rack::Utils.secure_compare(a, b)
    end
  end
end
