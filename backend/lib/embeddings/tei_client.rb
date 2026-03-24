require "json"
require "faraday"
require_relative "../config"

module Embeddings
  class TeiClient
    class Error < StandardError; end

    def initialize(base_url: Config.embedding_base_url)
      @conn = Faraday.new(url: base_url) do |f|
        f.request :json
        f.response :raise_error
        f.adapter Faraday.default_adapter
      end
    end

    def embed(text)
      res = @conn.post("/embed") { |req| req.body = { inputs: text } }
      parse_embedding(JSON.parse(res.body))
    rescue Faraday::Error => e
      raise Error, "Embedding request failed: #{e.message}"
    rescue JSON::ParserError => e
      raise Error, "Embedding response is not valid JSON: #{e.message}"
    end

    private

    def parse_embedding(payload)
      # TEI can return [Float,...] or [[Float,...], ...] based on endpoint shape.
      if payload.is_a?(Array) && payload.first.is_a?(Numeric)
        payload.map(&:to_f)
      elsif payload.is_a?(Array) && payload.first.is_a?(Array)
        payload.first.map(&:to_f)
      else
        raise Error, "Unexpected embedding payload shape: #{payload.class}"
      end
    end
  end
end
