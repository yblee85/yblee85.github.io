require "json"
require "sinatra/base"
require "rack/test"

require_relative "test_helper"
require_relative "../lib/auth/web_routes"

class AuthRoutesTest < Minitest::Test
  include Rack::Test::Methods

  class TestAuthApp < Sinatra::Base
    use Rack::Session::Pool, key: "rack.session", path: "/", httponly: true
    register Auth::WebRoutes
  end

  def app
    TestAuthApp
  end

  def oauth_env
    {
      "AUTH0_DOMAIN" => "example.auth0.com",
      "AUTH0_CLIENT_ID" => "cid",
      "AUTH0_CLIENT_SECRET" => "secret",
      "AUTH0_CALLBACK_URL" => "http://localhost:3001/auth/auth0/callback",
      "FRONTEND_ORIGIN" => "http://localhost:3000"
    }
  end

  def test_guest_login_sets_session_user_and_redirects
    with_env(oauth_env) do
      get "/auth/login?guest=true&return_to=http://localhost:3000/chat", {}, {
        "REMOTE_ADDR" => "1.2.3.4",
        "HTTP_HOST" => "localhost"
      }
      assert_equal 302, last_response.status
      assert_equal "http://localhost:3000/chat", last_response.headers["Location"]

      # Assert session was set during guest login (avoid a second request that can be blocked by rack-protection defaults).
      sess = last_request.env["rack.session"]
      refute_nil sess
      user = sess[:user] || sess["user"]
      refute_nil user
      assert_equal "Guest", user["name"] || user[:name]
      assert_equal "guest", user["type"] || user[:type]
      refute_nil user["user_id"] || user[:user_id]
    end
  end

  def test_guest_login_is_strict_true_only
    with_env(oauth_env) do
      get "/auth/login?guest=1&return_to=http://localhost:3000/chat", {}, {
        "REMOTE_ADDR" => "1.2.3.4",
        "HTTP_HOST" => "localhost"
      }
      assert_equal 400, last_response.status
      body = JSON.parse(last_response.body)
      assert_equal false, body["ok"]
      assert_equal "bad_request", body.dig("error", "code")
      assert_match(/connection is required/i, body.dig("error", "message"))
    end
  end

  def test_logout_guest_does_not_redirect_to_auth0
    with_env(oauth_env) do
      get "/auth/login?guest=true&return_to=http://localhost:3000/chat", {}, {
        "REMOTE_ADDR" => "1.2.3.4",
        "HTTP_HOST" => "localhost"
      }
      assert_equal 302, last_response.status

      get "/auth/logout?return_to=http://localhost:3000/chat", {}, { "HTTP_HOST" => "localhost" }
      assert_equal 302, last_response.status
      assert_equal "http://localhost:3000/chat", last_response.headers["Location"]
    end
  end

  def test_logout_oauth_user_redirects_to_auth0_logout
    with_env(oauth_env) do
      # Rack::Test provides rack.session to set session contents.
      get "/auth/logout?return_to=http://localhost:3000/chat",
          {},
          { "HTTP_HOST" => "localhost", "rack.session" => { user: { "type" => "oauth-user" } } }

      assert_equal 302, last_response.status
      location = last_response.headers["Location"].to_s
      assert_match(%r{\Ahttps://example\.auth0\.com/v2/logout\?}, location)
      assert_includes location, "returnTo=http%3A%2F%2Flocalhost%3A3000%2Fchat"
      assert_includes location, "client_id=cid"
    end
  end
end

