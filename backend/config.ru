require_relative "src/lib/config"
require "rack/cors"
require_relative "src/middleware/json_api_error_handler"

use Rack::Cors do
  allow do
    origins(*Config.cors_origins)
    resource "/auth/*", headers: :any, methods: %i[get post options head], credentials: true
    resource "/api/*",
      headers: :any,
      methods: %i[post options],
      credentials: true,
      expose: %w[x-ratelimit-remaining]
  end
end

use Middleware::JsonApiErrorHandler

require_relative "src/app"

run PortfolioApi
