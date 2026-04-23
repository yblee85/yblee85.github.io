require_relative "../../lib/embeddings/client"
require_relative "../../service/data/document_loader"

module Vector
  class InMemoryIndex
    Row = Struct.new(:id, :content, :metadata, :vector)

    def initialize(embedder: Embeddings::Client.build)
      @embedder = embedder
      @rows = []
      @mutex = Mutex.new
    end

    def build!(documents: PortfolioData::DocumentLoader.load_all)
      @mutex.synchronize do
        @rows = documents.map do |doc|
          metadata = doc.fetch(:metadata)
          embedding_text = build_embedding_text(
            content: doc.fetch(:content),
            metadata: metadata
          )

          Row.new(
            id: doc.fetch(:id),
            content: doc.fetch(:content),
            metadata: metadata,
            vector: embed_text(embedding_text, input_type: "document")
          )
        end
        self
      end
    end

    def search(query:, k: 5, min_score: nil)
      rows = @mutex.synchronize { @rows }
      query_vector = embed_text(query, input_type: "query")
      scored = rows.map do |row|
        score = cosine_similarity(query_vector, row.vector)
        row.to_h.merge(score: score)
      end

      ranked = scored.sort_by { |r| -r[:score] }
      ranked = ranked.select { |r| r[:score] >= min_score } if min_score

      results = ranked.first(k)

      # analytics
      analytics_payload = {
        query: query,
        k: k,
        min_score: min_score,
        count: ranked.count,
        results: results.map { |r| { id: r[:id], score: r[:score], context: r[:content][0..25] } }
      }
      Events::EventBus.instance.publish("rag.search", analytics_payload)

      results
    end

    private

    # Include important metadata in embedding text so queries like
    # "contribution at company C" can match documents even when company name
    # is primarily stored in metadata.
    def build_embedding_text(content:, metadata:)
      text_parts = [content.to_s]

      metadata.each do |key, value|
        case value
        when String, Numeric, TrueClass, FalseClass
          text_parts << "#{key}: #{value}"
        when Array
          flat = value.select { |v| v.is_a?(String) || v.is_a?(Numeric) }
          text_parts << "#{key}: #{flat.join(', ')}" unless flat.empty?
        end
      end

      text_parts.join("\n")
    end

    def cosine_similarity(a, b)
      return 0.0 if a.empty? || b.empty? || a.length != b.length

      dot = a.zip(b).sum { |x, y| x * y }
      na = Math.sqrt(a.sum { |x| x * x })
      nb = Math.sqrt(b.sum { |x| x * x })
      return 0.0 if na.zero? || nb.zero?

      dot / (na * nb)
    end

    def embed_text(text, input_type: "document")
      @embedder.embed(text, input_type: input_type)
    end
  end
end
