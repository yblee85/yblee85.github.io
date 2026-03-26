require_relative "test_helper"
require_relative "../lib/cache/local_store"

class LocalStoreTest < Minitest::Test
  def setup
    @store = Cache::LocalStore.new
  end

  def test_set_and_get
    @store.set("user-1", [1, 2, 3])

    assert_equal [1, 2, 3], @store.get("user-1")
  end

  def test_delete_removes_key
    @store.set("user-1", [1])

    assert_equal [1], @store.delete("user-1")
    assert_nil @store.get("user-1")
  end

  def test_clear_removes_all_keys
    @store.set("a", 1)
    @store.set("b", 2)

    @store.clear

    assert_empty @store.keys
  end

  def test_keys_returns_all_keys
    @store.set("a", 1)
    @store.set("b", 2)

    assert_equal %w[a b], @store.keys.sort
  end
end
