require "json"
require_relative "../lib/config"
require_relative "../lib/web/response"

module Middleware
  class RateLimiter
    Rule = Struct.new(:http_method, :path, :enabled)

    def initialize(app, limiter:, rules: Config.rate_limiter_rules)
      @app = app
      @limiter = limiter
      @rules = rules.map do |r|
        r.is_a?(Rule) ? r : Rule.new(**r)
      end
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

      return @app.call(env) if user_id.empty?

      unless @limiter.rate_limited?(user_id)
        body = Web::Response.error(
          code: "rate_limited",
          message: "rate limit exceeded: max #{Config.chat_max_requests_per_hour_per_user}/hour per user/ip"
        )
        return [429, { "Content-Type" => "application/json" }, [body.to_json]]
      end

      @limiter.record_visit(user_id)
      @app.call(env)
    end

    private

    def applies?(env)
      request_method = env["REQUEST_METHOD"].to_s
      path = env["PATH_INFO"].to_s
      @rules.any? do |r|
        r.enabled && r.http_method.to_s == request_method && r.path.to_s == path
      end
    end
  end
end
