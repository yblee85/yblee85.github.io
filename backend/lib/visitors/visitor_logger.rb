require_relative "../cache/local_store"
require_relative "../notifications/slack_notifier"
require_relative "../config"

module Visitors
  class VisitorLogger
    VISIT_TTL_S = 3600

    def initialize(cache: Cache::LocalStore.new, notifier: Notifications::SlackNotifier.new)
      @cache = cache
      @notifier = notifier
    end

    def subscribe(event_bus)
      event_bus.subscribe("auth.login") do |payload|
        mark_visit(payload[:user_id])
      end
      true
    end

    # Marks a visit for the given user_id.
    # - If already seen within TTL, no-op.
    # - Otherwise, caches the user_id for 1 hour and sends a Slack notification.
    def mark_visit(user_id)
      uid = user_id.to_s.strip
      raise ArgumentError, "user_id is required" if uid.empty?

      return false unless @cache.get(uid).nil?

      @cache.set(uid, true, ttl_s: VISIT_TTL_S)
      @notifier.send_message("Someone logged in to chat page")
      true
    end
  end
end
