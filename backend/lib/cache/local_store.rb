module Cache
  class LocalStore
    def initialize(sweep_interval: 60)
      @cache = {}
      start_sweeper(sweep_interval) if sweep_interval
    end

    def set(key, value, ttl_s: nil)
      @cache[key] = { value: value, expires_at: ttl_s ? Time.now + ttl_s : nil }
    end

    def get(key)
      entry = @cache[key]
      return nil if entry.nil?

      if entry[:expires_at] && Time.now > entry[:expires_at]
        @cache.delete(key)
        return nil
      end
      entry[:value]
    end

    def delete(key)
      @cache.delete(key)
      true
    end

    def clear
      @cache.clear
      true
    end

    def keys
      @cache.keys.select { |k| get(k) }
    end

    private

    def start_sweeper(interval)
      thread = Thread.new do
        loop do
          sleep interval
          now = Time.now
          @cache.delete_if { |_, e| e[:expires_at] && now > e[:expires_at] }
        end
      end
      thread.abort_on_exception = false
      thread
    end
  end
end
