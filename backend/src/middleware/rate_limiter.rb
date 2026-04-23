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

      rate_limiter_stats = @limiter.stats(user_id)
      if rate_limiter_stats[:rate_limited]
        body = Web::Response.error(
          code: "rate_limited",
          message: "rate limit exceeded: max #{rate_limiter_stats[:max_count]}/hour per user/ip"
        )
        headers = {
          "x-ratelimit-remaining" => rate_limiter_stats[:remaining_count].to_s,
          "Content-Type" => "application/json"
        }
        return [429, headers, [body.to_json]]
      end

      @limiter.record_visit(user_id)
      remaining = @limiter.stats(user_id)[:remaining_count]

      status, headers, body = @app.call(env)
      headers = headers.merge("x-ratelimit-remaining" => remaining.to_s)
      [status, headers, body]
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
