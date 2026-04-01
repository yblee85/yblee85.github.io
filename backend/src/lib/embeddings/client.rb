require_relative "../config"
require_relative "tei_client"
require_relative "voyage_client"

module Embeddings
  class Client
    def self.build(provider: Config.embedding_provider, **)
      case provider
      when "voyage"
        VoyageClient.new(**)
      when "tei"
        TeiClient.new
      else
        raise "Invalid embedding provider: #{provider}"
      end
    end
  end
end
