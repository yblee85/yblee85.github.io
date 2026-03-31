require_relative "../../test_helper"
require_relative "../../../src/service/rag/qa_service"

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
    attr_reader :last_user_prompt, :last_system_prompt, :last_history_size

    def initialize(configured: true, error: nil)
      @configured = configured
      @error = error
      @last_user_prompt = nil
      @last_system_prompt = nil
      @last_history_size = nil
    end

    def configured?
      @configured
    end

    def summarize(user_prompt:, system_prompt: nil, history: [])
      raise @error if @error

      @last_user_prompt = user_prompt
      @last_system_prompt = system_prompt
      @last_history_size = Array(history).length

      "summary: #{user_prompt} sys=#{system_prompt.to_s.strip.empty? ? 'none' : 'set'} hist=#{history.size}"
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

    assert_equal "Q&A service is not configured.", result[:answer]
    assert_equal "a", result[:sources].first[:id]
  end

  def test_calls_llm_with_built_prompts_when_hits_exist
    llm = FakeLlm.new(configured: true)
    hits = [{ id: "a", score: 0.9, metadata: {}, content: "worked on Slack alerts" }]
    service = Rag::QaService.new(
      index: FakeIndex.new(hits),
      embedder: Object.new,
      llm_client: llm
    )

    result = service.answer(question: "Tell me about Slack experience")

    assert_match "summary:", result[:answer]
    refute_nil llm.last_user_prompt
    assert_includes llm.last_user_prompt, "Tell me about Slack experience"
    assert_includes llm.last_user_prompt, "worked on Slack alerts"
    refute_nil llm.last_system_prompt
    refute_equal "", llm.last_system_prompt.to_s.strip
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
    refute_match "organization: Mappedin", result[:answer]
    assert_equal "a", result[:sources].first[:id]
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
