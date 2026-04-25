require_relative "../../test_helper"
require_relative "../../../src/lib/events/event_bus"
require_relative "../../../src/service/notifier/slack_listener"

class SlackListenerTest < Minitest::Test
  def test_subscribe_sends_message_on_auth_login
    bus = Events::EventBus.new
    notifier = Minitest::Mock.new
    notifier.expect(:send_message, true, ["Someone logged in to chat page (user-agent: TestAgent/1.0)"])

    listener = Notifier::SlackListener.new(slack_notifier: notifier)
    assert listener.subscribe(bus)
    assert bus.publish("auth.login", { user_id: "user-1", user_agent: "TestAgent/1.0" })

    notifier.verify
  end

  def test_subscribe_sends_error_message_on_llm_error
    bus = Events::EventBus.new
    notifier = Minitest::Mock.new

    err = RuntimeError.new("boom")
    notifier.expect(:send_message, true, ["LLM error: boom"])

    listener = Notifier::SlackListener.new(slack_notifier: notifier)
    listener.subscribe(bus)
    assert bus.publish("llm.error", { error: err })

    notifier.verify
  end
end
