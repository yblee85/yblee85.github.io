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

  def test_stats_for_user_with_no_visits
    limiter = Auth::RateLimiter.new(max_requests_per_hour_per_user: 3)
    user_id = "new-user"
    s = limiter.stats(user_id)
    assert_equal user_id, s[:user_id]
    assert_equal 3, s[:max_count]
    assert_equal 0, s[:current_count]
    assert_equal 3, s[:remaining_count]
    refute s[:rate_limited]
  end

  def test_stats_tracks_count_remaining_and_rate_limited_flag
    limiter = Auth::RateLimiter.new(max_requests_per_hour_per_user: 2)
    user_id = "u1"
    s0 = limiter.stats(user_id)
    assert_equal 0, s0[:current_count]
    assert_equal 2, s0[:remaining_count]
    refute s0[:rate_limited]

    limiter.record_visit(user_id)
    s1 = limiter.stats(user_id)
    assert_equal 1, s1[:current_count]
    assert_equal 1, s1[:remaining_count]
    refute s1[:rate_limited]

    limiter.record_visit(user_id)
    s2 = limiter.stats(user_id)
    assert_equal 2, s2[:current_count]
    assert_equal 0, s2[:remaining_count]
    assert s2[:rate_limited]
  end

  def test_stats_matches_pruned_window_like_rate_limited
    limiter = Auth::RateLimiter.new(max_requests_per_hour_per_user: 2)
    now_ms = 1_700_000_000_000
    cache = limiter.instance_variable_get(:@cache)
    user_id = "example-user-id"
    cache.set(user_id, [now_ms - 3_600_001, now_ms - 1_000])

    limiter.stub(:current_timestamp, now_ms) do
      s = limiter.stats(user_id)
      assert_equal 1, s[:current_count]
      assert_equal 1, s[:remaining_count]
      refute s[:rate_limited]
    end
  end
end
