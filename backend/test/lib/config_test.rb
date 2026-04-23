require_relative "../test_helper"
require_relative "../../src/lib/config"

class ConfigTest < Minitest::Test
  def test_defaults_are_applied
    with_env(
      "PORT" => nil,
      "ABOUTME_DATA_DIR_PATH" => nil,
      "EMBEDDING_PROVIDER" => nil,
      "EMBEDDING_BASE_URL" => nil,
      "VOYAGE_MODEL" => nil,
      "RAG_CHUNK_SIZE_CHARS" => nil,
      "RAG_CHUNK_OVERLAP_PERCENT" => nil,
      "ANTHROPIC_MODEL" => nil,
      "ANTHROPIC_MAX_OUTPUT_TOKENS" => nil,
      "MAX_CHAT_HISTORY" => nil
    ) do
      assert_equal 3000, Config.app_port
      assert_equal "./external/data", Config.aboutme_data_dir_path
      assert_equal "tei", Config.embedding_provider
      assert_equal "http://localhost:8080", Config.embedding_base_url
      assert_equal "voyage-4-lite", Config.voyage_model
      assert_equal 2000, Config.rag_chunk_size_chars
      assert_equal 10.0, Config.rag_chunk_overlap_percent
      assert_equal "claude-haiku-4-5", Config.anthropic_model
      assert_equal 2048, Config.anthropic_max_output_tokens
      assert_equal 6, Config.max_chat_history
    end
  end

  def test_validate_runtime_raises_for_missing_required_values
    Dir.mktmpdir do |dir|
      with_env(
        "ABOUTME_DATA_DIR_PATH" => dir,
        "EMBEDDING_PROVIDER" => "tei",
        "EMBEDDING_BASE_URL" => "http://localhost:8080",
        "ANTHROPIC_API_KEY" => nil
      ) do
        assert_raises(Config::ValidationError) { Config.validate_runtime! }
      end
    end
  end

  def test_validate_runtime_passes_for_valid_inputs
    Dir.mktmpdir do |dir|
      with_env(
        "ABOUTME_DATA_DIR_PATH" => dir,
        "EMBEDDING_PROVIDER" => "tei",
        "EMBEDDING_BASE_URL" => "http://localhost:8080",
        "ANTHROPIC_API_KEY" => "test-key"
      ) do
        assert Config.validate_runtime!
      end
    end
  end

  def test_validate_runtime_passes_for_voyage_provider
    Dir.mktmpdir do |dir|
      with_env(
        "ABOUTME_DATA_DIR_PATH" => dir,
        "EMBEDDING_PROVIDER" => "voyage",
        "VOYAGE_API_KEY" => "voyage-key",
        "ANTHROPIC_API_KEY" => "test-key"
      ) do
        assert Config.validate_runtime!
      end
    end
  end
end
