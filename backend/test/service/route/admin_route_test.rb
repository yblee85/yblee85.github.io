require "json"
require "sinatra/base"
require "rack/test"

require_relative "../../test_helper"
require_relative "../../../src/middleware/api_auth"
require_relative "../../../src/service/route/admin_route"
require_relative "../../../src/service/auth/user_role"

class AdminRouteTest < Minitest::Test
  include Rack::Test::Methods

  class SpyQa
    attr_reader :reindex_db_calls

    def initialize
      @reindex_db_calls = 0
    end

    def reindex_db
      @reindex_db_calls += 1
    end
  end

  class TestAdminApp < Sinatra::Base
    set :protection, false
    use Rack::Session::Pool, key: "rack.session", path: "/", httponly: true
    use Middleware::ApiAuth

    Container = Struct.new(:qa)
    set :container, Container.new(qa: SpyQa.new)

    register Route::AdminRoute
  end

  def setup
    @spy = SpyQa.new
    TestAdminApp.set :container, TestAdminApp::Container.new(qa: @spy)
  end

  def app
    TestAdminApp
  end

  def test_reindex_db_requires_authentication
    post "/api/admin/reindex_db", {}, { "HTTP_HOST" => "localhost" }

    assert_equal 401, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal false, body["ok"]
    assert_equal "authentication required", body.dig("error", "message")
    assert_equal 0, @spy.reindex_db_calls
  end

  def test_reindex_db_requires_admin_role
    post "/api/admin/reindex_db",
         {},
         {
           "HTTP_HOST" => "localhost",
           "rack.session" => {
             user: {
               "user_id" => "user-1",
               "roles" => [Auth::UserRole::USER]
             }
           }
         }

    assert_equal 401, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal false, body["ok"]
    assert_equal "admin access required", body.dig("error", "message")
    assert_equal 0, @spy.reindex_db_calls
  end

  def test_reindex_db_succeeds_for_admin
    post "/api/admin/reindex_db",
         {},
         {
           "HTTP_HOST" => "localhost",
           "rack.session" => {
             user: {
               "user_id" => "admin-1",
               "roles" => [Auth::UserRole::ADMIN]
             }
           }
         }

    assert_equal 200, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal true, body["ok"]
    assert_equal 1, @spy.reindex_db_calls
  end
end
