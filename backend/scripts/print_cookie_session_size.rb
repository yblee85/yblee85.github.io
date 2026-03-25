#!/usr/bin/env ruby
# frozen_string_literal: true

# Prints approximate Rack::Session::Cookie Set-Cookie sizes for the same options
# Sinatra uses with `enable :sessions` (encrypted cookie store). Compares a slim
# session (only `session[:user]`) vs a fat session that mirrors storing the full
# OmniAuth hash — useful for reasoning about ~4KB browser cookie limits.
#
# Usage (from repo backend/):
#   bundle exec ruby scripts/print_cookie_session_size.rb
#
# Optional: load real SESSION_SECRET from env (must be >= 64 bytes for rack-session).
#   set -a && source .env && set +a && bundle exec ruby scripts/print_cookie_session_size.rb

require "rack"
require "rack/mock"
require "rack/session/cookie"

require_relative "../lib/config"

def session_secret
  s = Config.session_secret
  if s.bytesize < 64
    warn "[print_cookie_session_size] SESSION_SECRET too short (#{s.bytesize} bytes); " \
         "using a 64-byte dummy secret for size measurement only."
    "a" * 64
  else
    s
  end
end

def measure(label, session_data)
  app = Rack::Session::Cookie.new(
    lambda do |env|
      env["rack.session"].merge!(session_data)
      [200, { "Content-Type" => "text/plain" }, ["ok"]]
    end,
    key: "rack.session",
    secret: session_secret,
    httponly: true,
    secure: false,
    same_site: Config.rack_env == "production" ? :none : :lax
  )

  _status, headers, _body = app.call(Rack::MockRequest.env_for("/"))
  raw = headers["set-cookie"] || headers["Set-Cookie"]
  unless raw
    warn "[print_cookie_session_size] #{label}: no Set-Cookie header"
    return
  end

  lines = Array(raw)
  total_line = lines.sum { |l| l.to_s.bytesize }
  # Extract rack.session= value; cookie may be split across attributes
  first_line = lines.first.to_s
  match = first_line.match(/\Arack\.session=([^;]+)/)
  value_len = match ? match[1].bytesize : nil

  v = value_len ? value_len.to_s : "n/a"
  puts "#{label.ljust(28)}  rack.session value bytes: #{v.rjust(5)}  " \
       "first Set-Cookie line bytes: #{first_line.bytesize.to_s.rjust(5)}"
  puts "  total Set-Cookie bytes (all headers): #{total_line}"
  puts "  reference: common per-cookie limit ~4096 bytes (Chrome; servers vary)"
end

slim_user = {
  "sub" => "auth0|1234567890",
  "name" => "Ada Lovelace",
  "email" => "ada@example.com",
  "picture" => "https://example.com/avatar.png"
}

# Realistic OmniAuth-style blob (tokens + raw_info) if the app stored the whole hash.
long_jwt = "eyJhbGciOiJSUzI1NiJ9.#{'x' * 1800}.#{'y' * 400}"
fat_omniauth = {
  "provider" => "auth0",
  "uid" => "auth0|1234567890",
  "info" => {
    "name" => "Ada Lovelace",
    "email" => "ada@example.com",
    "image" => "https://example.com/avatar.png"
  },
  "credentials" => {
    "token" => long_jwt,
    "id_token" => long_jwt,
    "expires_at" => Time.now.to_i + 3600,
    "expires" => true
  },
  "extra" => {
    "raw_info" => {
      "sub" => "auth0|1234567890",
      "nickname" => "ada",
      "name" => "Ada Lovelace",
      "picture" => "https://example.com/avatar.png",
      "updated_at" => "2025-01-01T00:00:00.000Z",
      "email" => "ada@example.com",
      "email_verified" => true
    }
  }
}

puts "RACK_ENV=#{Config.rack_env.inspect}"
puts

measure("slim: session[:user] only", { user: slim_user })
measure("fat: full omniauth-like hash", { "omniauth.auth" => fat_omniauth })
