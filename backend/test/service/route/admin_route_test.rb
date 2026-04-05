require "json"
require "sinatra/base"
require "rack/test"

require_relative "../../test_helper"
require_relative "../../../src/middleware/api_auth"
require_relative "../../../src/middleware/csrf_protection"
require_relative "../../../src/service/route/admin_route"
require_relative "../../../src/service/auth/user_role"
require_relative "../../../src/service/cli/commands/sync_portfolio_data"

class AdminRouteTest < Minitest::Test
  include Rack::Test::Methods

  CSRF_SESSION_TOKEN = "test-csrf-token".freeze

  class SpyQa
    attr_reader :reindex_db_calls

    def initialize(timeline: nil)
      @reindex_db_calls = 0
      @timeline = timeline
    end

    def reindex_db
      @reindex_db_calls += 1
      @timeline << :reindex if @timeline
    end
  end

  class TestAdminApp < Sinatra::Base
    set :protection, false
    use Rack::Session::Pool, key: "rack.session", path: "/", httponly: true
    use Middleware::ApiAuth
    use Middleware::CsrfProtection

    Container = Struct.new(:qa)
    set :container, Container.new(qa: SpyQa.new)

    register Route::AdminRoute
  end

  def setup
    @timeline = []
    @spy = SpyQa.new(timeline: @timeline)
    TestAdminApp.set :container, TestAdminApp::Container.new(qa: @spy)
  end

  def app
    TestAdminApp
  end

  def test_reindex_db_rejects_wrong_csrf_when_authenticated
    Cli::Commands::SyncPortfolioData.stub(:new, -> { raise "sync should not run" }) do
      post "/api/admin/reindex_db",
           {},
           {
             "HTTP_HOST" => "localhost",
             "HTTP_X_CSRF_TOKEN" => "wrong-token",
             "rack.session" => {
               user: {
                 "user_id" => "admin-1",
                 "roles" => [Auth::UserRole::ADMIN]
               },
               csrf_token: CSRF_SESSION_TOKEN
             }
           }
    end

    assert_equal 403, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal false, body["ok"]
    assert_equal "csrf_invalid", body.dig("error", "code")
    assert_equal 0, @spy.reindex_db_calls
  end

  def test_reindex_db_requires_authentication
    Cli::Commands::SyncPortfolioData.stub(:new, -> { raise "sync should not run" }) do
      post "/api/admin/reindex_db", {}, { "HTTP_HOST" => "localhost" }
    end

    assert_equal 401, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal false, body["ok"]
    assert_equal "authentication required", body.dig("error", "message")
    assert_equal 0, @spy.reindex_db_calls
  end

  def test_reindex_db_requires_admin_role
    Cli::Commands::SyncPortfolioData.stub(:new, -> { raise "sync should not run" }) do
      post "/api/admin/reindex_db",
           {},
           {
             "HTTP_HOST" => "localhost",
             "HTTP_X_CSRF_TOKEN" => CSRF_SESSION_TOKEN,
             "rack.session" => {
               user: {
                 "user_id" => "user-1",
                 "roles" => [Auth::UserRole::USER]
               },
               csrf_token: CSRF_SESSION_TOKEN
             }
           }
    end

    assert_equal 401, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal false, body["ok"]
    assert_equal "admin access required", body.dig("error", "message")
    assert_equal 0, @spy.reindex_db_calls
  end

  def test_reindex_db_succeeds_for_admin
    sync_result = Cli::Service::Result.new(ok: true, exit_code: 0, stdout: "", stderr: "")
    fake_sync_cmd = Object.new
    fake_sync_cmd.define_singleton_method(:call) do
      timeline = Thread.current[:_admin_route_test_timeline] || []
      timeline << :sync
      sync_result
    end

    Thread.current[:_admin_route_test_timeline] = @timeline
    begin
      Cli::Commands::SyncPortfolioData.stub(:new, -> { fake_sync_cmd }) do
        post "/api/admin/reindex_db",
             {},
             {
               "HTTP_HOST" => "localhost",
               "HTTP_X_CSRF_TOKEN" => CSRF_SESSION_TOKEN,
               "rack.session" => {
                 user: {
                   "user_id" => "admin-1",
                   "roles" => [Auth::UserRole::ADMIN]
                 },
                 csrf_token: CSRF_SESSION_TOKEN
               }
             }
      end

      assert_equal 200, last_response.status
      body = JSON.parse(last_response.body)
      assert_equal true, body["ok"]
      assert_equal true, body.dig("data", "synced")
      assert_equal true, body.dig("data", "reindexed")
      assert_equal 1, @spy.reindex_db_calls
      assert_equal %i[sync reindex], @timeline
    ensure
      Thread.current[:_admin_route_test_timeline] = nil
    end
  end

  def test_reindex_db_returns_500_when_sync_fails
    sync_result = Cli::Service::Result.new(ok: false, exit_code: 12, stdout: "", stderr: "nope")
    Cli::Commands::SyncPortfolioData.stub(:new, -> { Struct.new(:call).new(sync_result) }) do
      post "/api/admin/reindex_db",
           {},
           {
             "HTTP_HOST" => "localhost",
             "HTTP_X_CSRF_TOKEN" => CSRF_SESSION_TOKEN,
             "rack.session" => {
               user: {
                 "user_id" => "admin-1",
                 "roles" => [Auth::UserRole::ADMIN]
               },
               csrf_token: CSRF_SESSION_TOKEN
             }
           }
    end

    assert_equal 500, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal false, body["ok"]
    assert_equal "sync_failed", body.dig("error", "code")
    assert_equal 0, @spy.reindex_db_calls
  end
end
