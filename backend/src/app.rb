require "sinatra/base"
require "omniauth"
require "omniauth-auth0"
require "rack/session/pool"

require_relative "lib/config"
require_relative "lib/events/event_bus"
require_relative "app/portfolio_container"
require_relative "service/notifier/slack_listener"
require_relative "service/auth/rate_limiter"
require_relative "middleware/api_auth"
require_relative "middleware/rate_limiter"

require_relative "service/route/home_route"
require_relative "service/route/auth_route"
require_relative "service/route/chat_route"
require_relative "service/route/admin_route"

begin
  CONTAINER = App::PortfolioContainer.build
rescue Config::ValidationError => e
  warn "[config] #{e.message}"
  raise
end

class PortfolioApi < Sinatra::Base
  set :container, CONTAINER

  use Rack::Session::Pool,
      key: "rack.session",
      path: "/",
      httponly: true,
      secure: Config.rack_env == "production",
      same_site: Config.rack_env == "production" ? :none : :lax

  use Middleware::ApiAuth
  use Middleware::RateLimiter, limiter: Auth::RateLimiter.new, rules: Config.rate_limiter_rules

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

  if Config.slack_configured?
    slack_listener = Notifier::SlackListener.new
    slack_listener.subscribe(Events::EventBus.instance)
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
    p = request.path_info
    unless p.start_with?("/auth/login") ||
           p.start_with?("/auth/auth0") ||
           p == "/auth/failure" ||
           p.start_with?("/auth/logout")
      content_type :json
    end
  end

  register Route::HomeRoute
  register Route::AuthRoute
  register Route::ChatRoute
  register Route::AdminRoute
end

PortfolioApi.run! if $PROGRAM_NAME == __FILE__
