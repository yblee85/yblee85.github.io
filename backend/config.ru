require_relative "src/lib/config"
require "rack/cors"

use Rack::Cors do
  allow do
    origins(*Config.cors_origins)
    resource "/auth/*", headers: :any, methods: %i[get post options head], credentials: true
    resource "/api/chat", headers: :any, methods: %i[post options], credentials: true
  end
end

require_relative "src/app"

run PortfolioApi
