require "json"
require "faraday"
require_relative "../config"

module Embeddings
  class VoyageClient
    class Error < StandardError; end
    class RateLimitError < Error; end
    DEFAULT_MAX_RETRIES = 3
    DEFAULT_RETRY_SECONDS = 60
    EMBEDDINGS_PATH = "embeddings".freeze

    def initialize(
      api_key: Config.voyage_api_key,
      model: Config.voyage_model,
      base_url: "https://api.voyageai.com/v1",
      max_retries: DEFAULT_MAX_RETRIES
    )
      @model = model
      @max_retries = max_retries
      @conn = Faraday.new(url: base_url) do |f|
        f.request :json
        f.response :raise_error
        f.adapter Faraday.default_adapter
        f.headers["Authorization"] = "Bearer #{api_key}"
        f.headers["Content-Type"] = "application/json"
      end
    end

    def embed(text)
      attempts = 0

      begin
        res = @conn.post(EMBEDDINGS_PATH) do |req|
          req.body = {
            model: @model,
            input: [text.to_s],
            input_type: "document"
          }
        end

        parse_embedding(JSON.parse(res.body))
      rescue Faraday::TooManyRequestsError => e
        attempts += 1
        if attempts > @max_retries
          raise RateLimitError, "Voyage embedding rate-limited after #{attempts} attempts: #{e.message}"
        end

        error_message = e.response&.dig(:body)
        warn "[embeddings] Voyage 429 received: #{error_message}" if error_message
        sleep_seconds = retry_after_seconds
        warn "[embeddings] Voyage 429 received; retrying in #{sleep_seconds}s " \
             "(attempt #{attempts}/#{@max_retries})"
        sleep(sleep_seconds)
        retry
      rescue Faraday::Error => e
        raise Error, "Voyage embedding request failed: #{e.message}"
      rescue JSON::ParserError => e
        raise Error, "Voyage embedding response is not valid JSON: #{e.message}"
      end
    end

    private

    def retry_after_seconds
      DEFAULT_RETRY_SECONDS
    end

    def parse_embedding(payload)
      data = payload["data"]
      raise Error, "Unexpected Voyage payload shape: missing data" unless data.is_a?(Array) && !data.empty?

      vector = data.first["embedding"]
      raise Error, "Unexpected Voyage payload shape: missing embedding" unless vector.is_a?(Array)

      vector.map(&:to_f)
    end
  end
end
