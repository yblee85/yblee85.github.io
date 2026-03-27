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

  def embedding_provider
    string("EMBEDDING_PROVIDER", default: "tei")
  end

  def voyage_api_key
    ENV["VOYAGE_API_KEY"]
  end

  def voyage_model
    string("VOYAGE_MODEL", default: "voyage-4-lite")
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

  def rack_env
    string("RACK_ENV", default: "development")
  end

  def app_permitted_hosts
    ENV.fetch("APP_PERMITTED_HOSTS", "").split(",").map(&:strip).reject(&:empty?)
  end

  def auth0_domain
    string("AUTH0_DOMAIN", default: "")
  end

  def auth0_client_id
    string("AUTH0_CLIENT_ID", default: "")
  end

  def auth0_client_secret
    ENV["AUTH0_CLIENT_SECRET"].to_s
  end

  def auth0_callback_url
    string("AUTH0_CALLBACK_URL", default: "")
  end

  # Full URL Auth0 must allow (Regular Web App); default matches omniauth-auth0 callback_path.
  def auth0_expected_callback_url_hint
    return auth0_callback_url unless auth0_callback_url.strip.empty?

    "https://YOUR_API_HOST/auth/auth0/callback"
  end

  def frontend_origin
    string("FRONTEND_ORIGIN", default: "http://localhost:3000")
  end

  def cors_origins
    frontend_origin.split(",").map(&:strip).reject(&:empty?)
  end

  def session_secret
    ENV.fetch("SESSION_SECRET") { "dev-session-secret-change-me" }
  end

  def chat_max_requests_per_hour_per_user
    integer("CHAT_MAX_REQUESTS_PER_HOUR_PER_USER", default: 50, min: 1)
  end

  def slack_webhook_url
    ENV["SLACK_WEBHOOK_URL"].to_s.strip
  end

  def slack_channel
    ENV["SLACK_CHANNEL"].to_s.strip
  end

  def auth0_configured?
    !auth0_domain.strip.empty? &&
      !auth0_client_id.strip.empty? &&
      !auth0_client_secret.strip.empty?
  end

  def validate_runtime!
    validate_embedding_provider!
    runtime_check_required_keys!
    runtime_check_data_dir!
    runtime_check_tei_url!
    runtime_check_chunk_settings!
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

  def validate_embedding_provider!
    provider = embedding_provider
    return if %w[tei voyage].include?(provider)

    raise ValidationError, "EMBEDDING_PROVIDER must be one of: tei, voyage (got: #{provider})"
  end

  class << self
    private

    def runtime_check_required_keys!
      required_values = {
        "ABOUTME_DATA_DIR_PATH" => aboutme_data_dir_path,
        "ANTHROPIC_API_KEY" => anthropic_api_key
      }
      required_values["EMBEDDING_BASE_URL"] = embedding_base_url if embedding_provider == "tei"
      required_values["VOYAGE_API_KEY"] = voyage_api_key if embedding_provider == "voyage"

      missing = required_values.select { |_k, v| v.to_s.strip.empty? }.keys
      raise ValidationError, "Missing required config: #{missing.join(', ')}" unless missing.empty?
    end

    def runtime_check_data_dir!
      return if Dir.exist?(aboutme_data_dir_path)

      raise ValidationError, "ABOUTME_DATA_DIR_PATH does not exist: #{aboutme_data_dir_path}"
    end

    def runtime_check_tei_url!
      return unless embedding_provider == "tei"

      begin
        uri = URI.parse(embedding_base_url)
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          raise ValidationError, "EMBEDDING_BASE_URL must be http/https: #{embedding_base_url}"
        end
      rescue URI::InvalidURIError
        raise ValidationError, "EMBEDDING_BASE_URL is invalid: #{embedding_base_url}"
      end
    end

    def runtime_check_chunk_settings!
      raise ValidationError, "RAG_CHUNK_SIZE_CHARS must be > 0" unless rag_chunk_size_chars.positive?

      overlap = rag_chunk_overlap_percent
      return if overlap >= 0.0 && overlap < 100.0

      raise ValidationError, "RAG_CHUNK_OVERLAP_PERCENT must be >= 0 and < 100"
    end
  end
end
