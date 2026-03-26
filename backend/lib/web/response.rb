module Web
  module Response
    module_function

    def success(data: {}, message: nil)
      payload = { ok: true, data: data }
      payload[:message] = message unless message.nil?
      payload
    end

    def error(message:, code: "bad_request", details: nil)
      payload = {
        ok: false,
        error: {
          code: code,
          message: message
        }
      }
      payload[:error][:details] = details unless details.nil?
      payload
    end
  end
end
