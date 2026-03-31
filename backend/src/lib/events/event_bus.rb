module Events
  class EventBus
    def self.instance
      @instance ||= new
    end

    def initialize
      @subscribers = Hash.new { |h, k| h[k] = [] }
    end

    def subscribe(event_name, &block)
      raise ArgumentError, "block is required" unless block

      @subscribers[event_name] << block
      true
    end

    def publish(event_name, payload = {})
      @subscribers[event_name].each do |subscriber|
        subscriber.call(payload)
      rescue StandardError => e
        warn "[event_bus] subscriber_failed event=#{event_name} error=#{e.class}: #{e.message}"
      end
      true
    end
  end
end
