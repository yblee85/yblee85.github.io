require "minitest/autorun"
require "tmpdir"

module EnvHelpers
  def with_env(overrides)
    backup = ENV.to_hash
    overrides.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
    yield
  ensure
    ENV.replace(backup)
  end
end

class Minitest::Test
  include EnvHelpers
end
