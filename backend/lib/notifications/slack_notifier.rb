require "json"
require "faraday"
require_relative "../config"

module Notifications
  class SlackNotifier
    def initialize(webhook_url: Config.slack_webhook_url, default_channel: Config.slack_channel)
      @webhook_url = webhook_url.to_s.strip
      @default_channel = default_channel.to_s.strip
    end

    def send_message(message, channel: @default_channel)
      text = message.to_s
      raise ArgumentError, "message is required" if text.strip.empty?

      raise ArgumentError, "SLACK_WEBHOOK_URL is not configured" if @webhook_url.empty?

      payload = { text: text, channel: channel }
      res = Faraday.post(@webhook_url, JSON.generate(payload), "Content-Type" => "application/json")
      res.success?
    end
  end
end
