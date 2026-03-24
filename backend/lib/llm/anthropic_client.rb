require "langchain"
require_relative "../config"

module Llm
  class AnthropicClient
    class Error < StandardError; end

    def initialize(api_key: Config.anthropic_api_key, model: Config.anthropic_model)
      @api_key = api_key
      @model = model
      @llm = Langchain::LLM::Anthropic.new(api_key: @api_key) if configured?
    end

    def configured?
      !@api_key.to_s.strip.empty?
    end

    def summarize(question:, contexts:)
      raise Error, "ANTHROPIC_API_KEY is not set." unless configured?

      system_prompt = <<~SYSTEM_PROMPT
        You are a portfolio assistant for a software engineer who wants to promote himself to potential employers.
        You are factual and concise.
        Answer the user question using only the provided context snippets.
        Do not hallucinate and do not answer questions that are not related to the context.
        Good question example: "What was yunbo's contribution at mappedin?"
        Bad question example: "What is the capital of Canada?"
        If context is insufficient or the question cannot be answered directly from context,
        reply with exactly this sentence and nothing else:
        "I'm sorry, I don't have an answer for that."
        Do not provide partial guesses, extra background, or nearby information.
        Keep valid answers short: maximum 2 sentences.
      SYSTEM_PROMPT

      user_prompt = <<~USER_PROMPT
        Question:
        #{question}

        Context snippets:
        #{contexts.each_with_index.map { |c, i| "#{i + 1}. #{c}" }.join("\n")}
      USER_PROMPT

      # Anthropic Messages API: only "user" and "assistant" in `messages`.
      # System text must be the top-level `system` parameter (not role: "system").
      response = @llm.chat(
        system: system_prompt,
        messages: [
          { role: "user", content: user_prompt }
        ],
        model: @model,
        max_tokens: 120,
        temperature: 0.1
      )

      extract_text(response)
    rescue StandardError => e
      raise Error, "Anthropic request failed: #{e.message}"
    end

    private

    def extract_text(response)
      from_typed = text_from_langchain_response(response)
      return from_typed if from_typed

      payload = normalize_to_hash(response)
      from_payload = text_from_content_payload(payload)
      return from_payload if from_payload

      response.to_s
    end

    def text_from_langchain_response(response)
      if response.respond_to?(:chat_completion) && !response.chat_completion.to_s.strip.empty?
        return response.chat_completion
      end

      if response.respond_to?(:completion)
        completion_value = response.completion
        return completion_value if completion_value.is_a?(String) && !completion_value.strip.empty?
      end

      nil
    end

    def text_from_content_payload(payload)
      content = payload[:content] || payload["content"]
      return content.map { |part| part[:text] || part["text"] }.compact.join("\n") if content.is_a?(Array)

      completion = payload[:completion] || payload["completion"]
      return completion if completion.is_a?(String) && !completion.strip.empty?

      return content if content.is_a?(String) && !content.strip.empty?

      nil
    end

    def normalize_to_hash(response)
      return response if response.is_a?(Hash)

      return response.to_h if response.respond_to?(:to_h)

      {}
    end
  end
end
