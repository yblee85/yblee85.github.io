require "cgi"
require_relative "../config"
require_relative "../web/response"
require_relative "web_helpers"
require_relative "user_type"

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
        return handle_guest_login if guest_login_requested?

        handle_oauth_login
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

        Events::EventBus.instance.publish("auth.login", { user_id: user["user_id"] })

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
        return_to = safe_return_to(params["return_to"])
        user_type = session_user_type

        session.clear
        if user_type == UserType::OAUTH_USER
          redirect return_to unless oauth_ready?
          redirect auth0_logout_url(return_to)
        else
          redirect return_to
        end
      end
    end

    def self.register_me(app)
      app.get "/auth/me" do
        halt 401, Web::Response.error(code: "unauthorized", message: "not authenticated").to_json if session[:user].nil?

        Web::Response.success(data: { authenticated: true, user: session[:user] }).to_json
      end
    end
  end
end
