require "json"
require_relative "../../lib/config"
require_relative "../../lib/web/response"

module Route
  module ChatRoute
    def self.registered(app)
      register_chat(app)
    end

    def self.register_chat(app)
      app.post "/api/chat" do
        user_id = session[:user]["user_id"].to_s

        payload = JSON.parse(request.body.read)
        message = payload["message"].to_s.strip
        halt 400, Web::Response.error(code: "bad_request", message: "message is required").to_json if message.empty?

        response = settings.container.qa.answer(question: message, user_id: user_id)
        Web::Response.success(data: response).to_json
      rescue Embeddings::VoyageClient::RateLimitError => e
        halt 429, Web::Response.error(
          code: "voyage_rate_limited",
          message: "Voyage rate limit exceeded: #{e.message}"
        ).to_json
      rescue JSON::ParserError
        halt 400, Web::Response.error(code: "bad_request", message: "invalid JSON payload").to_json
      end
    end
  end
end
