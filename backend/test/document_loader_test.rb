require "json"
require "tmpdir"
require_relative "test_helper"
require_relative "../lib/data/document_loader"

class DocumentLoaderTest < Minitest::Test
  def test_chunk_text_applies_overlap
    chunks = PortfolioData::DocumentLoader.chunk_text(
      text: "abcdefghij",
      chunk_size_chars: 4,
      chunk_overlap_percent: 50
    )

    assert_equal %w[abcd cdef efgh ghij ij], chunks
  end

  def test_load_all_creates_chunked_documents_with_metadata
    Dir.mktmpdir do |dir|
      path = File.join(dir, "sample.json")
      File.write(
        path,
        JSON.generate(
          {
            collection_name: "portfolio",
            documents: [
              {
                id: "doc-1",
                contents: ["1234567890"],
                metadata: { "organization" => "Mappedin", "category" => "work" }
              }
            ]
          }
        )
      )

      docs = PortfolioData::DocumentLoader.load_all(
        data_dir: dir,
        chunk_size_chars: 4,
        chunk_overlap_percent: 50
      )

      assert_equal 5, docs.length
      assert_equal "doc-1#chunk-1", docs.first[:id]
      assert_equal "1234", docs.first[:content]
      assert_equal "portfolio", docs.first[:metadata]["_collection"]
      assert_equal path, docs.first[:metadata]["_source_file"]
      assert_equal "doc-1", docs.first[:metadata]["_base_id"]
      assert_equal 1, docs.first[:metadata]["_chunk_index"]
      assert_equal 5, docs.first[:metadata]["_chunk_total"]
    end
  end

  def test_load_all_joins_multiple_contents_with_newlines
    Dir.mktmpdir do |dir|
      path = File.join(dir, "multi.json")
      File.write(
        path,
        JSON.generate(
          {
            collection_name: "portfolio",
            documents: [
              {
                id: "doc-2",
                contents: %w[alpha beta],
                metadata: { "category" => "work" }
              }
            ]
          }
        )
      )

      docs = PortfolioData::DocumentLoader.load_all(
        data_dir: dir,
        chunk_size_chars: 100,
        chunk_overlap_percent: 0
      )

      assert_equal 1, docs.length
      assert_equal "alpha\nbeta", docs.first[:content]
    end
  end
end
