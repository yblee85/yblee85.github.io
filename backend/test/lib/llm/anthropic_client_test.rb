require_relative "../../test_helper"
require_relative "../../../src/lib/llm/anthropic_client"

class AnthropicClientTest < Minitest::Test
  FakeResponse = Struct.new(:chat_completion)

  class RecordingLlm
    attr_reader :calls

    def initialize
      @calls = []
    end

    def chat(**params)
      @calls << params
      FakeResponse.new("ok")
    end
  end

  def build_client
    client = Llm::AnthropicClient.new(api_key: "test-key", model: "test-model")
    recorder = RecordingLlm.new
    client.instance_variable_set(:@llm, recorder)
    [client, recorder]
  end

  def test_omits_system_when_nil
    client, recorder = build_client

    client.summarize(user_prompt: "hi", system_prompt: nil, history: [])

    params = recorder.calls.last
    refute params.key?(:system)
  end

  def test_omits_system_when_blank
    client, recorder = build_client

    client.summarize(user_prompt: "hi", system_prompt: "   ", history: [])

    params = recorder.calls.last
    refute params.key?(:system)
  end

  def test_sends_system_when_present
    client, recorder = build_client

    client.summarize(user_prompt: "hi", system_prompt: "SYS", history: [])

    params = recorder.calls.last
    assert_equal "SYS", params[:system]
  end

  def test_history_is_passed_as_messages_before_user_prompt
    client, recorder = build_client

    history = [
      { role: "user", content: "u1" },
      { role: "assistant", content: "a1" }
    ]
    client.summarize(user_prompt: "final", system_prompt: nil, history: history)

    params = recorder.calls.last
    messages = params[:messages]
    assert_equal(
      [
        { role: "user", content: "u1" },
        { role: "assistant", content: "a1" },
        { role: "user", content: "final" }
      ],
      messages
    )
  end
end
