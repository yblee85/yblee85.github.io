require_relative "../cache/local_store"
require_relative "../notifications/slack_notifier"
require_relative "../config"

module Chat
  class Chatroom
    CHAT_TTL_S = 3600

    def initialize(cache: Cache::LocalStore.new, max_history: Config.max_chat_history)
      @cache = cache
      @max_history = max_history
    end

    def add_question_and_answer(user_id:, question:, answer:)
      add_message(user_id, { role: "user", content: question })
      add_message(user_id, { role: "assistant", content: answer })
    end

    def add_message(user_id, message)
      messages = @cache.get(user_id) || []
      messages << message

      messages.shift if messages.length > @max_history

      @cache.set(user_id, messages, ttl_s: CHAT_TTL_S)
      messages
    end

    def get_messages(user_id)
      @cache.get(user_id) || []
    end
  end
end
