require "cgi"
require "uri"
require "digest"
require_relative "../config"
require_relative "../web/response"
require_relative "user_type"

module Auth
  # Sinatra route helpers for OAuth web flows (included via `app.helpers WebHelpers`).
  module WebHelpers
    def guest_login_requested?
      params["guest"].to_s.strip.downcase == "true"
    end

    def handle_guest_login
      session.clear

      ip = request.ip.to_s.strip
      halt 400, Web::Response.error(code: "bad_request", message: "could not determine client ip").to_json if ip.empty?

      session[:user] = guest_user_payload(ip)
      redirect safe_return_to(params["return_to"])
    end

    def handle_oauth_login
      halt_oauth_not_configured unless oauth_ready?

      connection = params["connection"].to_s.strip
      if connection.empty?
        halt 400, Web::Response.error(
          code: "bad_request",
          message: "connection is required (e.g. google-oauth2, github, linkedin)"
        ).to_json
      end

      session[:oauth_return_to] = safe_return_to(params["return_to"])
      redirect "/auth/auth0?connection=#{CGI.escape(connection)}"
    end

    def session_user_type
      return "" unless session[:user].is_a?(Hash)

      (session[:user]["type"] || session[:user][:type]).to_s
    end

    def oauth_ready?
      Config.auth0_configured?
    end

    def halt_oauth_not_configured
      halt 503,
           Web::Response.error(code: "oauth_not_configured", message: "OAuth is not configured on the server.").to_json
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

    def auth0_logout_url(return_to)
      URI::HTTPS.build(
        host: Config.auth0_domain,
        path: "/v2/logout",
        query: URI.encode_www_form(
          "client_id" => Config.auth0_client_id,
          "returnTo" => return_to
        )
      ).to_s
    end

    def user_payload_from_omniauth(auth)
      info = auth["info"] || {}
      email = info["email"].to_s.strip.downcase
      {
        "user_id" => hash_value(email),
        "sub" => (auth["uid"] || info["sub"]).to_s,
        "name" => info["name"],
        "email" => info["email"],
        "picture" => info["image"] || info["picture"],
        "type" => UserType::OAUTH_USER
      }.compact
    end

    def guest_user_payload(ip)
      {
        "user_id" => hash_value(ip),
        "name" => "Guest",
        "type" => UserType::GUEST
      }.compact
    end

    def hash_value(value)
      value.empty? ? nil : Digest::SHA256.hexdigest(value)
    end
  end
end
