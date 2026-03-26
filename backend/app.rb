require "json"
require "sinatra/base"
require "omniauth"
require "omniauth-auth0"
require "rack/session/pool"

require_relative "lib/config"
require_relative "lib/data/document_loader"
require_relative "lib/embeddings/tei_client"
require_relative "lib/embeddings/voyage_client"
require_relative "lib/vector/in_memory_index"
require_relative "lib/llm/anthropic_client"
require_relative "lib/rag/qa_service"
require_relative "lib/cache/local_store"
require_relative "lib/web/response"
require_relative "lib/auth/rate_limiter"
require_relative "lib/auth/web_routes"

begin
  Config.validate_runtime!
rescue Config::ValidationError => e
  warn "[config] #{e.message}"
  raise
end

class PortfolioApi < Sinatra::Base
  use Rack::Session::Pool,
      key: "rack.session",
      path: "/",
      httponly: true,
      secure: Config.rack_env == "production",
      same_site: Config.rack_env == "production" ? :none : :lax

  if Config.auth0_configured?
    use OmniAuth::Builder do
      provider :auth0,
               Config.auth0_client_id,
               Config.auth0_client_secret,
               Config.auth0_domain,
               {
                 callback_path: "/auth/auth0/callback",
                 scope: "openid profile email"
               }
    end
  end

  register Auth::WebRoutes

  configure do
    OmniAuth.config.allowed_request_methods = %i[get post]

    permitted_hosts = [
      *Config.app_permitted_hosts
    ]
    permitted_hosts.push(".localhost", "localhost", "127.0.0.1", "0.0.0.0") if Config.rack_env != "production"

    set :host_authorization, {
      permitted_hosts: permitted_hosts,
      allow_if: lambda { |env|
        path = env["PATH_INFO"]
        path == "/health" || path == "/" || path.start_with?("/auth")
      }
    }
    set :bind, "0.0.0.0"
    set :port, Config.app_port
  end

  before do
    p = request.path_info
    unless p.start_with?("/auth/login") ||
           p.start_with?("/auth/auth0") ||
           p == "/auth/failure" ||
           p.start_with?("/auth/logout")
      content_type :json
    end
  end

  DATA_DIR = Config.aboutme_data_dir_path
  CHUNK_SIZE_CHARS = Config.rag_chunk_size_chars
  CHUNK_OVERLAP_PERCENT = Config.rag_chunk_overlap_percent
  EMBEDDING_PROVIDER = Config.embedding_provider

  case EMBEDDING_PROVIDER
  when "voyage"
    EMBEDDER_FOR_INDEX = Embeddings::VoyageClient.new
    EMBEDDER_FOR_QA = Embeddings::VoyageClient.new(max_retries: 0)
  else
    EMBEDDER_FOR_INDEX = Embeddings::TeiClient.new
    # reuse
    EMBEDDER_FOR_QA = EMBEDDER_FOR_INDEX
  end
  DOCUMENTS = PortfolioData::DocumentLoader.load_all(
    data_dir: DATA_DIR,
    chunk_size_chars: CHUNK_SIZE_CHARS,
    chunk_overlap_percent: CHUNK_OVERLAP_PERCENT
  )
  INDEX = Vector::InMemoryIndex.new.build!(documents: DOCUMENTS, embedder: EMBEDDER_FOR_INDEX)
  QA = Rag::QaService.new(
    index: INDEX,
    embedder: EMBEDDER_FOR_QA,
    llm_client: Llm::AnthropicClient.new
  )
  RATE_LIMITER = Auth::RateLimiter.new

  get "/" do
    Web::Response.success.to_json
  end

  get "/health" do
    Web::Response.success(data: {
      docs: DOCUMENTS.length,
      embedding_provider: EMBEDDING_PROVIDER,
      chunk_size_chars: CHUNK_SIZE_CHARS,
      chunk_overlap_percent: CHUNK_OVERLAP_PERCENT
    }).to_json
  end

  post "/api/chat" do
    halt 401, Web::Response.error(code: "unauthorized", message: "authentication required").to_json if session[:user].nil?
    user_email = session[:user]["email"].to_s.strip
    unless RATE_LIMITER.record_visit(user_email)
      halt 429, Web::Response.error(
        code: "rate_limited",
        message: "rate limit exceeded: max #{Config.chat_max_requests_per_hour_per_user}/hour per user"
      ).to_json
    end

    payload = JSON.parse(request.body.read)
    message = payload["message"].to_s.strip
    halt 400, Web::Response.error(code: "bad_request", message: "message is required").to_json if message.empty?

    Web::Response.success(data: QA.answer(question: message)).to_json
  rescue Embeddings::VoyageClient::RateLimitError => e
    halt 429, Web::Response.error(
      code: "voyage_rate_limited",
      message: "Voyage rate limit exceeded: #{e.message}"
    ).to_json
  rescue JSON::ParserError
    halt 400, Web::Response.error(code: "bad_request", message: "invalid JSON payload").to_json
  end
end

PortfolioApi.run! if $PROGRAM_NAME == __FILE__
