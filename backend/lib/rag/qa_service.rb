module Rag
  class QaService
    def initialize(index:, embedder:, llm_client: nil)
      @index = index
      @embedder = embedder
      @llm_client = llm_client
    end

    def answer(question:, k: 5, min_score: 0.2)
      hits = @index.search(query: question, embedder: @embedder, k: k, min_score: min_score)
      contexts = hits.map { |h| h[:content] }

      answer_text =
        if @llm_client&.configured? && !contexts.empty?
          begin
            @llm_client.summarize(question: question, contexts: contexts)
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
  end
end
