require "json"

module PortfolioData
  module DocumentLoader
    module_function

    # Loads every *.json file under data_dir and returns normalized docs:
    # [{ id:, content:, metadata: }, ...] (JSON uses `contents` array per document, joined then chunked)
    def load_all(data_dir:, chunk_size_chars: 2000, chunk_overlap_percent: 10)
      docs = []
      Dir.glob(File.join(data_dir, "**", "*.json")).each do |path|
        parsed = JSON.parse(File.read(path))
        collection = parsed.fetch("collection_name")
        items = parsed.fetch("documents")

        items.each do |item|
          docs.concat(
            chunked_item_docs(
              item: item,
              collection: collection,
              source_path: path,
              chunk_size_chars: chunk_size_chars,
              chunk_overlap_percent: chunk_overlap_percent
            )
          )
        end
      end
      docs
    end

    def chunk_text(text:, chunk_size_chars:, chunk_overlap_percent:)
      source = text.to_s
      return [""] if source.empty?

      size = [chunk_size_chars.to_i, 1].max
      overlap = ((size * chunk_overlap_percent.to_f) / 100.0).floor
      overlap = overlap.clamp(0, size - 1)
      step = size - overlap

      chunks = []
      start = 0
      while start < source.length
        chunks << source[start, size]
        start += step
      end
      chunks
    end

    def item_source_text(item)
      Array(item.fetch("contents")).map(&:to_s).join("\n")
    end

    def chunked_item_docs(item:, collection:, source_path:, chunk_size_chars:, chunk_overlap_percent:)
      base_id = item.fetch("id")
      base_metadata = item.fetch("metadata").merge(
        "_collection" => collection,
        "_source_file" => source_path
      )
      chunks = chunk_text(
        text: item_source_text(item),
        chunk_size_chars: chunk_size_chars,
        chunk_overlap_percent: chunk_overlap_percent
      )
      chunks.map.with_index do |chunk_text, idx|
        {
          id: "#{base_id}#chunk-#{idx + 1}",
          content: chunk_text,
          metadata: base_metadata.merge(
            "_chunk_index" => idx + 1,
            "_chunk_total" => chunks.length,
            "_base_id" => base_id
          )
        }
      end
    end
  end
end
