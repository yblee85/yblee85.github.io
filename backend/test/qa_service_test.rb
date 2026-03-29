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

    def summarize(question:, contexts:, history: [])
      raise @error if @error

      "summary: #{question} (#{contexts.size}) hist=#{history.size}"
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
    hits = [
      {
        id: "a",
        score: 0.9,
        metadata: {
          "organization" => "Mappedin",
          "category" => "work_experience",
          "period" => { "start" => "2025-01", "end" => "2026-01" },
          "tags" => %w[snowflake etl]
        },
        content: "worked on Y"
      }
    ]
    service = Rag::QaService.new(
      index: FakeIndex.new(hits),
      embedder: Object.new,
      llm_client: FakeLlm.new(configured: true, error: RuntimeError.new("boom"))
    )

    result = service.answer(question: "what happened?")

    assert_match "LLM summarization unavailable", result[:answer]
    assert_match "organization: Mappedin", result[:answer]
    assert_match "category: work_experience", result[:answer]
    assert_match "period: 2025-01 to 2026-01", result[:answer]
    assert_match "tags: snowflake, etl", result[:answer]
    assert_match "worked on Y", result[:answer]
  end

  def test_passes_capped_history_to_llm
    with_env("MAX_CHAT_HISTORY" => "2") do
      hits = [{ id: "a", score: 0.9, metadata: {}, content: "ctx" }]
      service = Rag::QaService.new(
        index: FakeIndex.new(hits),
        embedder: Object.new,
        llm_client: FakeLlm.new(configured: true)
      )

      hist = [
        { "role" => "user", "content" => "first" },
        { "role" => "assistant", "content" => "second" },
        { "role" => "user", "content" => "third" },
        { "role" => "assistant", "content" => "fourth" }
      ]
      result = service.answer(question: "follow up", history: hist)

      assert_match "hist=2", result[:answer]
    end
  end
end
