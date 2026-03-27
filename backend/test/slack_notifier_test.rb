require_relative "test_helper"
require_relative "../lib/notifications/slack_notifier"

class SlackNotifierTest < Minitest::Test
  def test_send_message_posts_payload_and_returns_true_on_success
    notifier = Notifications::SlackNotifier.new(
      webhook_url: "https://hooks.slack.com/services/T000/B000/XXX",
      default_channel: "#default"
    )

    response = Struct.new(:success?).new(true)
    Faraday.stub(:post, response) do
      assert_equal true, notifier.send_message("hello", channel: "#random")
    end
  end

  def test_send_message_uses_default_channel_when_channel_blank
    notifier = Notifications::SlackNotifier.new(
      webhook_url: "https://hooks.slack.com/services/T000/B000/XXX",
      default_channel: "#default"
    )

    captured = nil
    response = Struct.new(:success?).new(true)
    Faraday.stub(:post, lambda { |url, body, headers|
      captured = [url, body, headers]
      response
    }) do
      notifier.send_message("hello")
    end

    url, body, headers = captured
    assert_equal "https://hooks.slack.com/services/T000/B000/XXX", url
    assert_equal({ "Content-Type" => "application/json" }, headers)
    assert_includes body, "\"channel\":\"#default\""
    assert_includes body, "\"text\":\"hello\""
  end

  def test_send_message_raises_when_webhook_missing
    notifier = Notifications::SlackNotifier.new(webhook_url: "", default_channel: "#default")

    assert_raises(ArgumentError) { notifier.send_message("hello", channel: "#random") }
  end
end
