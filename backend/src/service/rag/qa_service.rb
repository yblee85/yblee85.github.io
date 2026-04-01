require_relative "../../lib/config"

module Rag
  class QaService
    def initialize(index:, llm_client: nil, chatroom: nil)
      @index = index
      @llm_client = llm_client
      @chatroom = chatroom
    end

    def answer(question:, user_id:, k: 20, min_score: 0.2)
      history =
        if @chatroom
          @chatroom.get_messages(user_id)
        else
          []
        end

      hits = @index.search(query: question, k: k, min_score: min_score)
      contexts = hits.map { |h| format_hit_context(h) }
      user_prompt = generate_user_prompt(question: question, contexts: contexts)
      capped_history = normalize_history(history)

      answer_text =
        if @llm_client&.configured? && !contexts.empty?
          begin
            @llm_client.summarize(user_prompt: user_prompt, system_prompt: system_prompt, history: capped_history)
          rescue StandardError => e
            Events::EventBus.instance.publish("llm.error", { error: e })
            "LLM summarization unavailable (#{e.class}: #{e.message})."
          end
        elsif contexts.empty?
          "I could not find relevant information in the portfolio data."
        else
          "Q&A service is not configured."
        end

      @chatroom&.add_question_and_answer(user_id: user_id, question: question, answer: answer_text)

      {
        answer: answer_text,
        sources: hits.map { |h| { id: h[:id], score: h[:score], metadata: h[:metadata] } }
      }
    end

    def reindex_db
      @index.build!
    end

    private

    def system_prompt
      <<~SYSTEM_PROMPT
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
    end

    def generate_user_prompt(question:, contexts:)
      <<~USER_PROMPT
        Question:
        #{question}

        Context snippets:
        #{contexts.each_with_index.map { |c, i| "#{i + 1}. #{c}" }.join("\n")}
      USER_PROMPT
    end

    def normalize_history(raw)
      return [] if Config.max_chat_history <= 0

      arr = Array(raw).filter_map do |h|
        role = (h["role"] || h[:role]).to_s
        content = (h["content"] || h[:content]).to_s.strip
        next if content.empty?
        next unless %w[user assistant].include?(role)

        { role: role, content: content }
      end
      arr.last(Config.max_chat_history)
    end

    def format_hit_context(hit)
      metadata = hit[:metadata] || {}
      lines = []
      lines << "id: #{hit[:id]}" if hit[:id]
      lines.concat(metadata_lines(metadata))
      lines << "content: #{hit[:content]}"
      lines.join("\n")
    end

    def metadata_lines(metadata)
      lines = []
      org = meta_value(metadata, "organization")
      lines << "organization: #{org}" if org

      cat = meta_value(metadata, "category")
      lines << "category: #{cat}" if cat

      period_line = period_line_for(metadata)
      lines << period_line if period_line

      tags_line = tags_line_for(metadata)
      lines << tags_line if tags_line
      lines
    end

    def meta_value(metadata, key)
      val = metadata[key] || metadata[key.to_sym]
      return if val.nil? || val.to_s.strip.empty?

      val
    end

    def period_line_for(metadata)
      period = metadata["period"] || metadata[:period]
      return unless period.is_a?(Hash)

      start_value = period["start"] || period[:start]
      end_value = period["end"] || period[:end]
      return unless start_value || end_value

      "period: #{start_value} to #{end_value}"
    end

    def tags_line_for(metadata)
      tags = metadata["tags"] || metadata[:tags]
      return unless tags.is_a?(Array) && !tags.empty?

      "tags: #{tags.join(', ')}"
    end
  end
end
