require_relative "../config"

module Rag
  class QaService
    def initialize(index:, embedder:, llm_client: nil)
      @index = index
      @embedder = embedder
      @llm_client = llm_client
    end

    def answer(question:, history: nil, k: 20, min_score: 0.2)
      hits = @index.search(query: question, embedder: @embedder, k: k, min_score: min_score)
      contexts = hits.map { |h| format_hit_context(h) }
      capped_history = normalize_history(history)

      answer_text =
        if @llm_client&.configured? && !contexts.empty?
          begin
            @llm_client.summarize(question: question, contexts: contexts, history: capped_history)
          rescue StandardError => e
            # Graceful degradation: retrieval still works even if LLM vendor config fails.
            "LLM summarization unavailable (#{e.class}: #{e.message}).\n" \
            "Relevant context:\n- #{contexts.join("\n- ")}"
          end
        elsif contexts.empty?
          "I could not find relevant information in the portfolio data."
        else
          # Fallback when LLM is not configured.
          "Relevant context:\n- #{contexts.join("\n- ")}"
        end

      {
        answer: answer_text,
        sources: hits.map { |h| { id: h[:id], score: h[:score], metadata: h[:metadata] } }
      }
    end

    private

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
