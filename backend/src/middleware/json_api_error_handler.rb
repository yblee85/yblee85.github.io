require_relative "../lib/config"
require_relative "../lib/events/event_bus"
require_relative "../lib/web/response"

module Middleware
  class JsonApiErrorHandler
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue StandardError => e
      raise e unless env["PATH_INFO"].to_s.start_with?("/api/")

      warn "[api] #{e.class}: #{e.message}\n#{e.backtrace&.first(30)&.join("\n")}"
      message = Config.rack_env == "production" ? "An unexpected error occurred." : e.message
      Events::EventBus.instance.publish("error", { error: e })
      body = Web::Response.error(code: "internal_error", message: message).to_json
      [500, { "content-type" => "application/json; charset=utf-8" }, [body]]
    end
  end
end
