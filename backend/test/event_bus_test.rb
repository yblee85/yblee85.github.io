require_relative "test_helper"
require_relative "../lib/events/event_bus"

class EventBusTest < Minitest::Test
  def test_publish_invokes_subscribers_with_payload
    bus = Events::EventBus.new
    received = []
    bus.subscribe("test.action") { |payload| received << payload[:user_id] }

    bus.publish("test.action", { user_id: "user@example.com" })

    assert_equal ["user@example.com"], received
  end

  def test_publish_continues_when_subscriber_raises
    bus = Events::EventBus.new
    received = []
    bus.subscribe("test.action") { |_payload| raise "boom" }
    bus.subscribe("test.action") { |payload| received << payload[:user_id] }

    assert bus.publish("test.action", { user_id: "user@example.com" })
    assert_equal ["user@example.com"], received
  end
end
