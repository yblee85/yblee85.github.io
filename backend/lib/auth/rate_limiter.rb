module Auth
  class RateLimiter
    def initialize(
      max_requests_per_hour_per_user: Config.chat_max_requests_per_hour_per_user
    )
      @cache = Cache::LocalStore.new
      @max_requests_per_hour_per_user = max_requests_per_hour_per_user
    end

    # Returns true if the user is not rate limited and the visit is recorded, false otherwise.
    def record_visit(user_id)
      rate_limited = rate_limited?(user_id)
      return false if rate_limited

      visits_in_past_hour = get_past_hour_timestamps(user_id)
      visits_in_past_hour << current_timestamp
      @cache.set(user_id, visits_in_past_hour)
      true
    end

    # Returns true if the user is rate limited, false otherwise.
    def rate_limited?(user_id)
      visits_in_past_hour = get_past_hour_timestamps(user_id)
      return false if visits_in_past_hour.length < @max_requests_per_hour_per_user

      true
    end

    private

    def current_timestamp
      (Time.now.to_f * 1000).to_i
    end

    def get_past_hour_timestamps(user_id)
      timestamps = @cache.get(user_id)
      if timestamps.nil? || timestamps.empty?
        @cache.delete(user_id)
        return []
      end
      past_hour_timestamp = current_timestamp - 3_600_000
      filtered_timestamps = timestamps.select { |timestamp| timestamp >= past_hour_timestamp }
      @cache.set(user_id, filtered_timestamps)
      filtered_timestamps
    end
  end
end
