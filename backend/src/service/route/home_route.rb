require_relative "../../lib/config"
require_relative "../../lib/web/response"

module Route
  module HomeRoute
    def self.registered(app)
      register_home(app)
      register_health(app)
    end

    def self.register_home(app)
      app.get "/" do
        Web::Response.success.to_json
      end
    end

    def self.register_health(app)
      app.get "/health" do
        c = settings.container
        Web::Response.success(data: {
                                docs: c.documents.length,
                                embedding_provider: c.embedding_provider,
                                chunk_size_chars: c.chunk_size_chars,
                                chunk_overlap_percent: c.chunk_overlap_percent
                              }).to_json
      end
    end
  end
end
