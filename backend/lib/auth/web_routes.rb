require "cgi"
require_relative "../config"
require_relative "web_helpers"

module Auth
  module WebRoutes
    def self.registered(app)
      app.helpers WebHelpers
      register_login(app)
      register_callback(app)
      register_failure(app)
      register_logout(app)
      register_me(app)
    end

    def self.register_login(app)
      app.get "/auth/login" do
        halt_oauth_not_configured unless oauth_ready?

        connection = params["connection"].to_s.strip
        if connection.empty?
          halt 400, { error: "connection is required (e.g. google-oauth2, github, linkedin)" }.to_json
        end

        session[:oauth_return_to] = safe_return_to(params["return_to"])
        redirect "/auth/auth0?connection=#{CGI.escape(connection)}"
      end
    end

    def self.register_callback(app)
      app.get "/auth/auth0/callback" do
        halt_oauth_not_configured unless oauth_ready?

        auth = request.env["omniauth.auth"]
        halt 401, { error: "authentication failed" }.to_json unless auth

        session[:user] = user_payload_from_omniauth(auth)

        return_to = session.delete(:oauth_return_to) || Config.frontend_origin.split(",").first.strip
        redirect return_to
      end
    end

    def self.register_failure(app)
      app.get "/auth/failure" do
        message = params["message"] || "unknown"
        halt 400, { error: "auth failure: #{message}" }.to_json
      end
    end

    def self.register_logout(app)
      app.get "/auth/logout" do
        return_to = safe_return_to(params["return_to"])
        session.clear
        redirect return_to unless oauth_ready?

        redirect auth0_logout_url(return_to)
      end
    end

    def self.register_me(app)
      app.get "/auth/me" do
        halt 401, { authenticated: false }.to_json if session[:user].nil?

        { authenticated: true, user: session[:user] }.to_json
      end
    end
  end
end
