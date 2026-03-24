require "uri"

module Config
  class ValidationError < StandardError; end

  module_function

  def app_port
    integer("PORT", default: 3000, min: 1)
  end

  def aboutme_data_dir_path
    string("ABOUTME_DATA_DIR_PATH", default: "./external/data")
  end

  def embedding_base_url
    string("EMBEDDING_BASE_URL", default: "http://localhost:8080")
  end

  def rag_chunk_size_chars
    integer("RAG_CHUNK_SIZE_CHARS", default: 2000, min: 1)
  end

  def rag_chunk_overlap_percent
    float("RAG_CHUNK_OVERLAP_PERCENT", default: 10.0, min: 0.0, max: 99.0)
  end

  def anthropic_api_key
    ENV["ANTHROPIC_API_KEY"]
  end

  def anthropic_model
    string("ANTHROPIC_MODEL", default: "claude-haiku-4-5")
  end

  # Fail-fast runtime validation.
  # Call this once at app boot so misconfiguration is caught immediately.
  def validate_runtime!
    required_values = {
      "ABOUTME_DATA_DIR_PATH" => aboutme_data_dir_path,
      "EMBEDDING_BASE_URL" => embedding_base_url,
      "ANTHROPIC_API_KEY" => anthropic_api_key
    }

    missing = required_values.select { |_k, v| v.to_s.strip.empty? }.keys
    raise ValidationError, "Missing required config: #{missing.join(', ')}" unless missing.empty?

    unless Dir.exist?(aboutme_data_dir_path)
      raise ValidationError, "ABOUTME_DATA_DIR_PATH does not exist: #{aboutme_data_dir_path}"
    end

    begin
      uri = URI.parse(embedding_base_url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        raise ValidationError, "EMBEDDING_BASE_URL must be http/https: #{embedding_base_url}"
      end
    rescue URI::InvalidURIError
      raise ValidationError, "EMBEDDING_BASE_URL is invalid: #{embedding_base_url}"
    end

    raise ValidationError, "RAG_CHUNK_SIZE_CHARS must be > 0" unless rag_chunk_size_chars.positive?

    overlap = rag_chunk_overlap_percent
    raise ValidationError, "RAG_CHUNK_OVERLAP_PERCENT must be >= 0 and < 100" unless overlap >= 0.0 && overlap < 100.0

    true
  end

  def string(name, default:)
    value = ENV[name]
    return default if value.nil? || value.strip.empty?

    value
  end

  def integer(name, default:, min: nil, max: nil)
    raw = ENV[name]
    value = if raw.nil? || raw.strip.empty?
              default
            else
              Integer(raw)
            end
    value = min if !min.nil? && value < min
    value = max if !max.nil? && value > max
    value
  rescue ArgumentError
    default
  end

  def float(name, default:, min: nil, max: nil)
    raw = ENV[name]
    value = if raw.nil? || raw.strip.empty?
              default
            else
              Float(raw)
            end
    value = min if !min.nil? && value < min
    value = max if !max.nil? && value > max
    value
  rescue ArgumentError
    default
  end
end
