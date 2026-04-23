require "anthropic"
require_relative "../config"

module Llm
  class AnthropicClient
    class Error < StandardError; end

    def initialize(api_key: Config.anthropic_api_key, model: Config.anthropic_model)
      @api_key = api_key
      @model = model
      @client = Anthropic::Client.new(api_key: @api_key) if configured?
    end

    def configured?
      !@api_key.to_s.strip.empty?
    end

    def summarize(user_prompt:, system_prompt: nil, history: [])
      raise Error, "ANTHROPIC_API_KEY is not set." unless configured?

      history = Array(history)

      messages = []
      history.each do |turn|
        role = (turn[:role] || turn["role"]).to_s
        content = (turn[:content] || turn["content"]).to_s
        next if content.strip.empty?
        next unless %w[user assistant].include?(role)

        messages << { role: role.to_sym, content: content }
      end
      messages << { role: :user, content: user_prompt }

      params = {
        messages: messages,
        model: @model,
        max_tokens: Config.anthropic_max_output_tokens,
        temperature: 0.1
      }
      system_text = system_prompt.to_s.strip
      params[:system_] = system_text unless system_text.empty?

      response = @client.messages.create(**params)

      extract_text(response)
    rescue StandardError => e
      raise Error, "Anthropic request failed: #{e.message}"
    end

    private

    def extract_text(response)
      if response.respond_to?(:content)
        parts = Array(response.content).map { |block| text_from_content_block(block) }.compact
        return parts.join("\n") unless parts.empty?
      end

      payload = normalize_to_hash(response)
      from_payload = text_from_content_payload(payload)
      return from_payload if from_payload

      response.to_s
    end

    def text_from_content_block(block)
      return block.text if block.respond_to?(:text) && block.text.is_a?(String) && !block.text.strip.empty?

      if block.is_a?(Hash)
        return block[:text] || block["text"] if block[:type] == :text || block["type"] == "text"

        return block[:text] || block["text"]
      end

      nil
    end

    def text_from_content_payload(payload)
      content = payload[:content] || payload["content"]
      return content.map { |part| text_from_content_block(part) }.compact.join("\n") if content.is_a?(Array)

      completion = payload[:completion] || payload["completion"]
      return completion if completion.is_a?(String) && !completion.strip.empty?

      return content if content.is_a?(String) && !content.strip.empty?

      nil
    end

    def normalize_to_hash(response)
      return response if response.is_a?(Hash)

      return response.to_h if response.respond_to?(:to_h)

      {}
    end
  end
end
