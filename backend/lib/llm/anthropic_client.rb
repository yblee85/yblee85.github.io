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
        If context is insufficient, say you are not sure.
      SYSTEM_PROMPT

      user_prompt = <<~USER_PROMPT
        Question:
        #{question}

        Context snippets:
        #{contexts.each_with_index.map { |c, i| "#{i + 1}. #{c}" }.join("\n")}
      USER_PROMPT

      response = @llm.chat(
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt }
        ],
        model: @model,
        max_tokens: 400,
        temperature: 0.1
      )

      extract_text(response)
    rescue StandardError => e
      raise Error, "Anthropic request failed: #{e.message}"
    end

    private

    def extract_text(response)
      # langchainrb can return either a hash-like payload or a typed response object.
      if response.respond_to?(:chat_completion) && !response.chat_completion.to_s.strip.empty?
        return response.chat_completion
      end

      # Some adapters expose #completion directly on the response object.
      if response.respond_to?(:completion)
        completion_value = response.completion
        return completion_value if completion_value.is_a?(String) && !completion_value.strip.empty?
      end

      payload = normalize_to_hash(response)
      content = payload[:content] || payload["content"]

      if content.is_a?(Array)
        return content.map { |part| part[:text] || part["text"] }.compact.join("\n")
      end

      # Some adapters may return plain text in :completion.
      completion = payload[:completion] || payload["completion"]
      return completion if completion.is_a?(String) && !completion.strip.empty?

      if content.is_a?(String) && !content.strip.empty?
        return content
      end

      response.to_s
    end

    def normalize_to_hash(response)
      return response if response.is_a?(Hash)
      return response.to_h if response.respond_to?(:to_h)
      {}
    end
  end
end
