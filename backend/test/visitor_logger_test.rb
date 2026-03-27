require_relative "test_helper"
require_relative "../lib/events/event_bus"
require_relative "../lib/visitors/visitor_logger"

class VisitorLoggerTest < Minitest::Test
  def test_subscribe_registers_auth_login_handler
    cache = Cache::LocalStore.new(sweep_interval: nil)
    notifier = Minitest::Mock.new
    notifier.expect(:send_message, true, ["Someone logged in to chat page"])
    bus = Events::EventBus.new

    with_env("SLACK_CHANNEL" => "#test") do
      logger = Visitors::VisitorLogger.new(cache: cache, notifier: notifier)
      assert logger.subscribe(bus)
      assert bus.publish("auth.login", { user_id: "user-1" })
      assert_equal true, cache.get("user-1")
    end

    notifier.verify
  end

  def test_mark_visit_sends_once_per_ttl
    cache = Cache::LocalStore.new(sweep_interval: nil)
    notifier = Minitest::Mock.new
    notifier.expect(:send_message, true, ["Someone logged in to chat page"])

    with_env("SLACK_CHANNEL" => "#test") do
      logger = Visitors::VisitorLogger.new(cache: cache, notifier: notifier)

      assert_equal true, logger.mark_visit("user-1")
      assert_equal false, logger.mark_visit("user-1")
    end

    notifier.verify
  end

  def test_mark_visit_allows_again_after_expiration
    cache = Cache::LocalStore.new(sweep_interval: nil)
    notifier = Minitest::Mock.new

    with_env("SLACK_CHANNEL" => "#test") do
      logger = Visitors::VisitorLogger.new(cache: cache, notifier: notifier)

      notifier.expect(:send_message, true, ["Someone logged in to chat page"])
      assert logger.mark_visit("user-1")

      cache.set("user-1", true, ttl_s: -1) # expire immediately

      notifier.expect(:send_message, true, ["Someone logged in to chat page"])
      assert logger.mark_visit("user-1")
    end

    notifier.verify
  end
end
