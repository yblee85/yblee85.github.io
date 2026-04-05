require "securerandom"

module Auth
  module CsrfToken
    HEADER_NAME = "X-CSRF-Token".freeze

    module_function

    def ensure!(session)
      s = session || {}
      tok = s[:csrf_token] || s["csrf_token"]
      if tok.nil? || tok.to_s.empty?
        tok = SecureRandom.urlsafe_base64(32)
        s[:csrf_token] = tok
      end
      tok
    end

    def read(session)
      s = session || {}
      (s[:csrf_token] || s["csrf_token"]).to_s
    end
  end
end
