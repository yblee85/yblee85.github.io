require_relative "lib/config"
require "rack/cors"

use Rack::Cors do
  allow do
    origins(*Config.cors_origins)
    resource "/auth/*", headers: :any, methods: %i[get post options head], credentials: true
  end
end

require_relative "app"

run PortfolioApi
