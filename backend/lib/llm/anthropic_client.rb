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

    def summarize(question:, contexts:, history: [])
      raise Error, "ANTHROPIC_API_KEY is not set." unless configured?

      history = Array(history)

      system_prompt = <<~SYSTEM_PROMPT
        ## Role
        You are a factual, concise portfolio assistant for a software engineer speaking to potential employers.

        ## Grounding
        Answer only from the context snippets in the latest user message. Do not hallucinate; ignore questions unrelated to that context.
        Prior conversation turns exist only to interpret follow-ups (e.g. "tell me more about that"). Do not treat earlier assistant replies as a second source of facts.

        ## Snippet selection
        Retrieval is imperfect: ignore snippets that do not clearly match the question (wrong organization, wrong topic, or generic filler). Do not blend unrelated snippets into one answer.

        ## Organization-specific questions
        For questions scoped to a company (e.g. mappedin, medstack, rt7), prioritize snippets that name that organization and summarize concrete contributions. If such snippets exist, do not refuse.

        ## Metadata
        Use each snippet's metadata when choosing among candidates:
        - period: align with the timeframe asked when relevant.
        - category: prefer the right kind of entry (e.g. work_experience vs personal_growth).
        - tags: use tags to pick the best-matching detail.
        When snippets conflict, prefer the best combined fit: organization, period, category, tags.

        ## Examples
        On-topic: "What was yunbo's contribution at mappedin?" Off-topic: "What is the capital of Canada?"

        ## When you cannot answer
        If context is insufficient, reply with exactly this and nothing else: "I'm sorry, I don't have an answer for that." No partial guesses or extra background.

        ## Inviting follow-up (optional)
        Keep the main answer summarized. Afterward, if other snippets in the same context list are clearly related to the user's topic but you did not use them in the answer, add one short sentence inviting them to ask more (e.g. other companies, tools, projects, or periods you see in those snippets or metadata). Only mention angles that actually appear in context; never invent topics. If nothing substantive remains to explore in the snippets, skip this sentence entirely.

        ## Length
        At most 5 sentences total, including the optional invitation sentence.
      SYSTEM_PROMPT

      user_prompt = <<~USER_PROMPT
        Question:
        #{question}

        Context snippets:
        #{contexts.each_with_index.map { |c, i| "#{i + 1}. #{c}" }.join("\n")}
      USER_PROMPT

      messages = []
      history.each do |turn|
        role = (turn[:role] || turn["role"]).to_s
        content = (turn[:content] || turn["content"]).to_s
        next if content.strip.empty?
        next unless %w[user assistant].include?(role)

        messages << { role: role, content: content }
      end
      messages << { role: "user", content: user_prompt }

      # Anthropic Messages API: only "user" and "assistant" in `messages`.
      # System text must be the top-level `system` parameter (not role: "system").
      response = @llm.chat(
        system: system_prompt,
        messages: messages,
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
