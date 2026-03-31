module Notifier
  class SlackListener
    def initialize(slack_notifier: Notifications::SlackNotifier.new)
      @slack_notifier = slack_notifier
    end

    def subscribe(event_bus)
      event_bus.subscribe("auth.login") do |_|
        @slack_notifier.send_message("Someone logged in to chat page")
      end

      event_bus.subscribe("llm.error") do |payload|
        message = "LLM error: #{payload[:error].message}"
        @slack_notifier.send_message(message)
      end

      true
    end
  end
end
