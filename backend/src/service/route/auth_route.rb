require "cgi"
require_relative "../../lib/config"
require_relative "../../lib/web/response"
require_relative "../../service/auth/web_helpers"
require_relative "../../service/auth/user_type"
require_relative "../../service/auth/csrf_token"

module Route
  module AuthRoute
    def self.registered(app)
      app.helpers Auth::WebHelpers
      app.helpers self

      register_login(app)
      register_callback(app)
      register_failure(app)
      register_logout(app)
      register_me(app)
    end

    def self.register_login(app)
      app.get "/auth/login" do
        handle_login
      end
    end

    def self.register_callback(app)
      app.get "/auth/auth0/callback" do
        halt_oauth_not_configured unless oauth_ready?

        auth = request.env["omniauth.auth"]
        halt 401, Web::Response.error(code: "unauthorized", message: "authentication failed").to_json unless auth

        return_to = session.delete(:oauth_return_to) || Config.frontend_origin.split(",").first.strip
        user = user_payload_from_omniauth(auth)

        session[:user] = user
        Auth::CsrfToken.ensure!(session)

        Events::EventBus.instance.publish("auth.login",
                                          { user_id: user["user_id"], user_agent: request.user_agent.to_s })

        redirect return_to
      end
    end

    def self.register_failure(app)
      app.get "/auth/failure" do
        message = params["message"] || "unknown"
        halt 400, Web::Response.error(code: "auth_failure", message: "auth failure: #{message}").to_json
      end
    end

    def self.register_logout(app)
      app.get %r{/auth/logout/?} do
        handle_logout
      end
    end

    def self.register_me(app)
      app.get "/auth/me" do
        halt 401, Web::Response.error(code: "unauthorized", message: "not authenticated").to_json if session[:user].nil?

        token = Auth::CsrfToken.ensure!(session)
        Web::Response.success(data: { authenticated: true, user: session[:user], csrf_token: token }).to_json
      end
    end

    def handle_login
      return handle_guest_login if guest_login_requested?

      handle_oauth_login
    end

    def handle_logout
      return_to = safe_return_to(params["return_to"])
      user_type = session_user_type

      session.clear
      if user_type == Auth::UserType::OAUTH_USER
        redirect return_to unless oauth_ready?
        redirect auth0_logout_url(return_to)
      else
        redirect return_to
      end
    end

    def handle_guest_login
      session.clear

      ip = request.ip.to_s.strip
      halt 400, Web::Response.error(code: "bad_request", message: "could not determine client ip").to_json if ip.empty?
      user = guest_user_payload(ip)
      session[:user] = user
      Auth::CsrfToken.ensure!(session)

      Events::EventBus.instance.publish("auth.login", { user_id: user["user_id"], user_agent: request.user_agent.to_s })

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
  end
end
