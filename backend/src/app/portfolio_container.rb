require_relative "../lib/config"
require_relative "../service/vector/in_memory_index"
require_relative "../lib/llm/anthropic_client"
require_relative "../service/rag/qa_service"
require_relative "../service/chat/chatroom"

module App
  class PortfolioContainer
    Container = Struct.new(
      :qa
    )

    def self.build
      Config.validate_runtime!

      qa = Rag::QaService.new(
        index: Vector::InMemoryIndex.new.build!,
        llm_client: Llm::AnthropicClient.new,
        chatroom: Chat::Chatroom.new
      )

      Container.new(
        qa: qa
      )
    rescue Config::ValidationError => e
      warn "[config] #{e.message}"
      raise
    end
  end
end
