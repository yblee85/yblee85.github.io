require "cgi"
require "uri"
require_relative "../config"

module Auth
  module WebRoutes
    def self.registered(app)
      app.helpers do
        def oauth_ready?
          Config.auth0_configured?
        end

        def halt_oauth_not_configured
          halt 503, { error: "OAuth is not configured on the server." }.to_json
        end

        def safe_return_to(url)
          return Config.frontend_origin if url.nil? || url.strip.empty?

          uri = URI.parse(url)
          allowed = URI.parse(Config.frontend_origin.split(",").first.strip)
          return url if uri.scheme == allowed.scheme && uri.host == allowed.host

          Config.frontend_origin.split(",").first.strip
        rescue URI::InvalidURIError
          Config.frontend_origin.split(",").first.strip
        end
      end

      # Stores return URL, then hands off to OmniAuth (/auth/auth0).
      app.get "/auth/login" do
        halt_oauth_not_configured unless oauth_ready?

        connection = params["connection"].to_s.strip
        if connection.empty?
          halt 400, { error: "connection is required (e.g. google-oauth2, github, linkedin)" }.to_json
        end

        session[:oauth_return_to] = safe_return_to(params["return_to"])
        redirect "/auth/auth0?connection=#{CGI.escape(connection)}"
      end

      # OmniAuth sets request.env["omniauth.auth"] after Auth0 redirects here.
      app.get "/auth/auth0/callback" do
        halt_oauth_not_configured unless oauth_ready?

        auth = request.env["omniauth.auth"]
        halt 401, { error: "authentication failed" }.to_json unless auth

        info = auth["info"] || {}
        session[:user] = {
          "sub" => (auth["uid"] || info["sub"]).to_s,
          "name" => info["name"],
          "email" => info["email"],
          "picture" => info["image"] || info["picture"]
        }.compact

        return_to = session.delete(:oauth_return_to) || Config.frontend_origin.split(",").first.strip
        redirect return_to
      end

      app.get "/auth/failure" do
        message = params["message"] || "unknown"
        halt 400, { error: "auth failure: #{message}" }.to_json
      end

      app.get "/auth/logout" do
        return_to = safe_return_to(params["return_to"])
        session.clear

        unless oauth_ready?
          redirect return_to
          return
        end

        logout_url = URI::HTTPS.build(
          host: Config.auth0_domain,
          path: "/v2/logout",
          query: URI.encode_www_form(
            "client_id" => Config.auth0_client_id,
            "returnTo" => return_to
          )
        ).to_s
        redirect logout_url
      end

      app.get "/auth/me" do
        if session[:user].nil?
          halt 401, { authenticated: false }.to_json
        end

        { authenticated: true, user: session[:user] }.to_json
      end
    end
  end
end
