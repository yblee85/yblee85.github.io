require "json"
require "sinatra/base"
require "omniauth"
require "omniauth-auth0"
require "digest"
require "rack/session/pool"

require_relative "lib/config"
require_relative "lib/data/document_loader"
require_relative "lib/embeddings/tei_client"
require_relative "lib/embeddings/voyage_client"
require_relative "lib/vector/in_memory_index"
require_relative "lib/llm/anthropic_client"
require_relative "lib/rag/qa_service"
require_relative "lib/auth/web_routes"

begin
  Config.validate_runtime!
rescue Config::ValidationError => e
  warn "[config] #{e.message}"
  raise
end

class PortfolioApi < Sinatra::Base
  # Use a server-side session store so cookies stay small/stable.
  use Rack::Session::Pool,
      key: "rack.session",
      path: "/",
      httponly: true,
      secure: Config.rack_env == "production",
      same_site: Config.rack_env == "production" ? :none : :lax

  # Register OmniAuth before enable :sessions so Rack prepends Session on top of OmniAuth
  # (Session -> OmniAuth -> Sinatra); OmniAuth needs the session for OAuth state.
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

  helpers do
    def log_session_state(tag:)
      cookie = request.env["HTTP_COOKIE"].to_s
      rack_session_values = cookie.scan(/rack\.session=([^;]+)/).flatten
      first = rack_session_values.first
      last = rack_session_values.last
      $stderr.puts(
        "[session-debug] #{tag} method=#{request.request_method} path=#{request.path_info} " \
        "origin=#{request.env['HTTP_ORIGIN'].inspect} " \
        "rack_session_count=#{rack_session_values.length} " \
        "rack_session_first_sha=#{first.nil? ? nil : Digest::SHA256.hexdigest(first)[0, 12]} " \
        "rack_session_last_sha=#{last.nil? ? nil : Digest::SHA256.hexdigest(last)[0, 12]} " \
        "session_user_present=#{!session[:user].nil?}"
      )
    rescue StandardError => e
      $stderr.puts("[session-debug] #{tag} log_failed=#{e.class}: #{e.message}")
    end
  end

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
    if request.path_info == "/auth/me" || request.path_info == "/api/chat"
      log_session_state(tag: "before")
    end

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

  get "/" do
    {
      ok: true
    }.to_json
  end

  get "/health" do
    {
      ok: true,
      docs: DOCUMENTS.length,
      embedding_provider: EMBEDDING_PROVIDER,
      chunk_size_chars: CHUNK_SIZE_CHARS,
      chunk_overlap_percent: CHUNK_OVERLAP_PERCENT
    }.to_json
  end

  post "/api/chat" do
    log_session_state(tag: "chat")
    halt 401, { error: "authentication required" }.to_json if session[:user].nil?

    payload = JSON.parse(request.body.read)
    message = payload["message"].to_s.strip
    halt 400, { error: "message is required" }.to_json if message.empty?

    QA.answer(question: message).to_json
  rescue Embeddings::VoyageClient::RateLimitError => e
    halt 429, { error: "Voyage rate limit exceeded: #{e.message}" }.to_json
  rescue JSON::ParserError
    halt 400, { error: "invalid JSON payload" }.to_json
  end
end

PortfolioApi.run! if $PROGRAM_NAME == __FILE__
