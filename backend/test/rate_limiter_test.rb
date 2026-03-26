require_relative "test_helper"
require_relative "../lib/config"
require_relative "../lib/cache/local_store"
require_relative "../lib/auth/rate_limiter"

class RateLimiterTest < Minitest::Test
  def test_record_visit_returns_true_under_limit
    limiter = Auth::RateLimiter.new(max_requests_per_hour_per_user: 2)

    assert_equal true, limiter.record_visit("user@example.com")
    assert_equal true, limiter.record_visit("user@example.com")
    assert_equal false, limiter.record_visit("user@example.com")
  end

  def test_rate_limited_reflects_current_count
    limiter = Auth::RateLimiter.new(max_requests_per_hour_per_user: 1)

    refute limiter.rate_limited?("user@example.com")
    assert limiter.record_visit("user@example.com")
    assert limiter.rate_limited?("user@example.com")
  end

  def test_old_visits_are_pruned_before_limit_check
    limiter = Auth::RateLimiter.new(max_requests_per_hour_per_user: 2)
    now_ms = 1_700_000_000_000
    cache = limiter.instance_variable_get(:@cache)
    cache.set("user@example.com", [now_ms - 3_600_001, now_ms - 1_000])

    limiter.stub(:current_timestamp, now_ms) do
      refute limiter.rate_limited?("user@example.com")
      assert_equal [now_ms - 1_000], cache.get("user@example.com")
      assert limiter.record_visit("user@example.com")
      assert limiter.rate_limited?("user@example.com")
    end
  end
end
