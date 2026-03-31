require_relative "../../test_helper"
require_relative "../../../src/lib/config"
require_relative "../../../src/lib/cache/local_store"
require_relative "../../../src/service/auth/rate_limiter"

class RateLimiterTest < Minitest::Test
  def test_rate_limited_after_max_visits_are_recorded
    limiter = Auth::RateLimiter.new(max_requests_per_hour_per_user: 2)

    refute limiter.rate_limited?("example-user-id")
    limiter.record_visit("example-user-id")
    refute limiter.rate_limited?("example-user-id")

    limiter.record_visit("example-user-id")
    assert limiter.rate_limited?("example-user-id")
  end

  def test_rate_limited_reflects_current_count
    limiter = Auth::RateLimiter.new(max_requests_per_hour_per_user: 1)

    refute limiter.rate_limited?("example-user-id")
    limiter.record_visit("example-user-id")
    assert limiter.rate_limited?("example-user-id")
  end

  def test_old_visits_are_pruned_before_limit_check
    limiter = Auth::RateLimiter.new(max_requests_per_hour_per_user: 2)
    now_ms = 1_700_000_000_000
    cache = limiter.instance_variable_get(:@cache)
    user_id = "example-user-id"
    cache.set(user_id, [now_ms - 3_600_001, now_ms - 1_000])

    limiter.stub(:current_timestamp, now_ms) do
      refute limiter.rate_limited?("example-user-id")
      assert_equal [now_ms - 1_000], cache.get(user_id)
      limiter.record_visit("example-user-id")
      assert limiter.rate_limited?("example-user-id")
    end
  end
end
