module Cache
  class LocalStore
    def initialize
      @cache = {}
    end

    def set(key, value)
      @cache[key] = value
    end

    def get(key)
      @cache[key]
    end

    def delete(key)
      @cache.delete(key)
    end

    def clear
      @cache.clear
    end

    def keys
      @cache.keys
    end
  end
end
