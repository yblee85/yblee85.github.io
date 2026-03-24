require_relative "test_helper"
require_relative "../lib/rag/qa_service"

class QaServiceTest < Minitest::Test
  class FakeIndex
    def initialize(hits)
      @hits = hits
    end

    def search(query:, embedder:, k:, min_score:)
      [query, embedder, k, min_score]
      @hits
    end
  end

  class FakeLlm
    def initialize(configured: true, error: nil)
      @configured = configured
      @error = error
    end

    def configured?
      @configured
    end

    def summarize(question:, contexts:)
      raise @error if @error

      "summary: #{question} (#{contexts.size})"
    end
  end

  def test_returns_context_fallback_when_llm_is_not_configured
    hits = [{ id: "a", score: 0.9, metadata: { "k" => "v" }, content: "worked on X" }]
    service = Rag::QaService.new(
      index: FakeIndex.new(hits),
      embedder: Object.new,
      llm_client: FakeLlm.new(configured: false)
    )

    result = service.answer(question: "what did you do?")

    assert_match "Relevant context:", result[:answer]
    assert_equal "a", result[:sources].first[:id]
  end

  def test_returns_empty_message_when_no_hits
    service = Rag::QaService.new(
      index: FakeIndex.new([]),
      embedder: Object.new,
      llm_client: FakeLlm.new(configured: true)
    )

    result = service.answer(question: "unknown")

    assert_equal "I could not find relevant information in the portfolio data.", result[:answer]
    assert_empty result[:sources]
  end

  def test_gracefully_handles_llm_errors
    hits = [{ id: "a", score: 0.9, metadata: {}, content: "worked on Y" }]
    service = Rag::QaService.new(
      index: FakeIndex.new(hits),
      embedder: Object.new,
      llm_client: FakeLlm.new(configured: true, error: RuntimeError.new("boom"))
    )

    result = service.answer(question: "what happened?")

    assert_match "LLM summarization unavailable", result[:answer]
    assert_match "worked on Y", result[:answer]
  end
end
