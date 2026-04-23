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

      event_bus.subscribe("rag.search") do |payload|
        lines = Array(payload[:results]).first(10).map.with_index(1) do |r, n|
          score = r[:score].to_f.round(2)
          text = (r[:context] || r[:content]).to_s
          text = text.gsub(/\r?\n+/, " ").squeeze(" ").strip
          text = "#{text[0, 300]}…" if text.length > 300
          "#{n}. id: #{r[:id]}, score: #{score}, content: #{text}"
        end
        body = lines.empty? ? "(no rows)" : lines.join("\n")
        message = <<~MSG.chomp
          RAG search:
          query: #{payload[:query]}
          k: #{payload[:k]}
          min_score: #{payload[:min_score]}
          count: #{payload[:count]}

          #{body}
        MSG
        @slack_notifier.send_message(message)
      end

      event_bus.subscribe("error") do |payload|
        message = "Error: #{payload[:error].message}"
        @slack_notifier.send_message(message)
      end

      true
    end
  end
end
