require_relative "../lib/config"
require_relative "../service/data/document_loader"
require_relative "../lib/embeddings/tei_client"
require_relative "../lib/embeddings/voyage_client"
require_relative "../service/vector/in_memory_index"
require_relative "../lib/llm/anthropic_client"
require_relative "../service/rag/qa_service"
require_relative "../service/auth/rate_limiter"
require_relative "../service/chat/chatroom"

module App
  class PortfolioContainer
    Container = Struct.new(
      :documents,
      :qa,
      :rate_limiter,
      :chatroom,
      :embedding_provider,
      :chunk_size_chars,
      :chunk_overlap_percent
    )

    def self.build
      Config.validate_runtime!

      embedding_provider = Config.embedding_provider
      embedder_for_index, embedder_for_qa =
        case embedding_provider
        when "voyage"
          [Embeddings::VoyageClient.new, Embeddings::VoyageClient.new(max_retries: 0)]
        else
          tei = Embeddings::TeiClient.new
          [tei, tei]
        end

      chunk_size_chars = Config.rag_chunk_size_chars
      chunk_overlap_percent = Config.rag_chunk_overlap_percent

      documents = PortfolioData::DocumentLoader.load_all(
        data_dir: Config.aboutme_data_dir_path,
        chunk_size_chars: chunk_size_chars,
        chunk_overlap_percent: chunk_overlap_percent
      )

      index = Vector::InMemoryIndex.new.build!(documents: documents, embedder: embedder_for_index)
      qa = Rag::QaService.new(index: index, embedder: embedder_for_qa, llm_client: Llm::AnthropicClient.new)

      Container.new(
        documents: documents,
        qa: qa,
        rate_limiter: Auth::RateLimiter.new,
        chatroom: Chat::Chatroom.new,
        embedding_provider: embedding_provider,
        chunk_size_chars: chunk_size_chars,
        chunk_overlap_percent: chunk_overlap_percent
      )
    rescue Config::ValidationError => e
      warn "[config] #{e.message}"
      raise
    end
  end
end
