require_relative "../../test_helper"
require_relative "../../../src/lib/llm/anthropic_client"

class AnthropicClientTest < Minitest::Test
  FakeTextBlock = Struct.new(:text)
  FakeMessage = Struct.new(:content)

  class RecordingMessages
    attr_reader :calls

    def initialize
      @calls = []
    end

    def create(**params)
      @calls << params
      FakeMessage.new(content: [FakeTextBlock.new(text: "ok")])
    end
  end

  class RecordingClient
    attr_reader :messages_api

    def initialize
      @messages_api = RecordingMessages.new
    end

    def messages
      @messages_api
    end
  end

  def build_client
    client = Llm::AnthropicClient.new(api_key: "test-key", model: "test-model")
    recorder = RecordingClient.new
    client.instance_variable_set(:@client, recorder)
    [client, recorder.messages_api]
  end

  def test_omits_system_when_nil
    client, recorder = build_client

    client.summarize(user_prompt: "hi", system_prompt: nil, history: [])

    params = recorder.calls.last
    refute params.key?(:system_)
  end

  def test_omits_system_when_blank
    client, recorder = build_client

    client.summarize(user_prompt: "hi", system_prompt: "   ", history: [])

    params = recorder.calls.last
    refute params.key?(:system_)
  end

  def test_sends_system_when_present
    client, recorder = build_client

    client.summarize(user_prompt: "hi", system_prompt: "SYS", history: [])

    params = recorder.calls.last
    assert_equal "SYS", params[:system_]
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
        { role: :user, content: "u1" },
        { role: :assistant, content: "a1" },
        { role: :user, content: "final" }
      ],
      messages
    )
  end
end
