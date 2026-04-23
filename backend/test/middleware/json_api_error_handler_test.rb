require "json"
require_relative "../test_helper"
require_relative "../../src/middleware/json_api_error_handler"

class JsonApiErrorHandlerTest < Minitest::Test
  class RaisingApp
    def initialize(message: "boom")
      @message = message
    end

    def call(_env)
      raise StandardError, @message
    end
  end

  class OkApp
    def call(_env)
      [200, { "content-type" => "text/plain" }, ["ok"]]
    end
  end

  def test_passes_through_when_inner_app_succeeds
    handler = Middleware::JsonApiErrorHandler.new(OkApp.new)
    status, headers, body = handler.call("PATH_INFO" => "/api/chat", "REQUEST_METHOD" => "POST")
    assert_equal 200, status
    assert_equal "ok", body.join
    assert_includes headers["content-type"], "text/plain"
  end

  def test_returns_json_500_for_api_path_with_exception_message_in_development
    handler = Middleware::JsonApiErrorHandler.new(RaisingApp.new(message: "embedding failed"))
    with_env("RACK_ENV" => "development") do
      status, headers, body = handler.call("PATH_INFO" => "/api/chat", "REQUEST_METHOD" => "POST")
      assert_equal 500, status
      assert_includes headers["content-type"], "application/json"
      payload = JSON.parse(body.join)
      assert_equal false, payload["ok"]
      assert_equal "internal_error", payload.dig("error", "code")
      assert_equal "embedding failed", payload.dig("error", "message")
    end
  end

  def test_returns_generic_message_in_production
    handler = Middleware::JsonApiErrorHandler.new(RaisingApp.new(message: "secret details"))
    with_env("RACK_ENV" => "production") do
      status, _headers, body = handler.call("PATH_INFO" => "/api/admin/reindex_db", "REQUEST_METHOD" => "POST")
      assert_equal 500, status
      payload = JSON.parse(body.join)
      assert_equal "An unexpected error occurred.", payload.dig("error", "message")
    end
  end

  def test_covers_any_path_starting_with_slash_api_slash
    handler = Middleware::JsonApiErrorHandler.new(RaisingApp.new)
    with_env("RACK_ENV" => "development") do
      status, _, body = handler.call("PATH_INFO" => "/api/foo/bar", "REQUEST_METHOD" => "POST")
      assert_equal 500, status
      assert_equal "internal_error", JSON.parse(body.join).dig("error", "code")
    end
  end

  def test_re_raises_for_non_api_path_so_other_handlers_apply
    handler = Middleware::JsonApiErrorHandler.new(RaisingApp.new(message: "health check failed"))
    err = assert_raises(StandardError) do
      handler.call("PATH_INFO" => "/health", "REQUEST_METHOD" => "GET")
    end
    assert_equal "health check failed", err.message
  end
end
