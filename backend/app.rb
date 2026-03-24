require "json"
require "sinatra/base"

require_relative "lib/config"
require_relative "lib/data/document_loader"
require_relative "lib/embeddings/tei_client"
require_relative "lib/embeddings/voyage_client"
require_relative "lib/vector/in_memory_index"
require_relative "lib/llm/anthropic_client"
require_relative "lib/rag/qa_service"

begin
  Config.validate_runtime!
rescue Config::ValidationError => e
  warn "[config] #{e.message}"
  raise
end

class PortfolioApi < Sinatra::Base
  configure do
    set :bind, "0.0.0.0"
    set :port, Config.app_port
  end

  before do
    content_type :json
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

  get "/health" do
    {
      ok: true,
      docs: DOCUMENTS.length,
      embedding_provider: EMBEDDING_PROVIDER,
      chunk_size_chars: CHUNK_SIZE_CHARS,
      chunk_overlap_percent: CHUNK_OVERLAP_PERCENT
    }.to_json
  end

  # TODO: Enable chat later
  post "/api/chat" do
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
