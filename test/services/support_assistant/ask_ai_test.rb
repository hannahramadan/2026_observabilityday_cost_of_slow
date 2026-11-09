require "test_helper"

class AskAiTest < ActiveSupport::TestCase
  CHAT_RESPONSE = {
    id: "chatcmpl-1", object: "chat.completion", created: 1, model: "test-model",
    choices: [{ index: 0, message: { role: "assistant", content: "Reset it in Settings." }, finish_reason: "stop" }],
    usage: { prompt_tokens: 120, completion_tokens: 30, total_tokens: 150 }
  }.freeze

  def stub_chat(body: CHAT_RESPONSE, status: 200)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  test "returns the answer text and token counts" do
    stub_chat
    reply = SupportAssistant::AskAi.new.call(question: "How do I reset my password?", docs: "Reset it in Settings.")
    assert_equal "Reset it in Settings.", reply.text
    assert_equal 120, reply.input_tokens
    assert_equal 30, reply.output_tokens
  end

  test "the instrumentation records a chat span with GenAI attributes" do
    stub_chat
    SupportAssistant::AskAi.new.call(question: "q", docs: "d")
    span = finished_spans.find { |s| s.attributes["gen_ai.operation.name"] == "chat" }
    assert span, "no chat span; spans seen: #{finished_spans.map(&:name).inspect}"
    assert_equal "openai", span.attributes["gen_ai.provider.name"]
    assert_equal 120, span.attributes["gen_ai.usage.input_tokens"]
    assert_equal 30, span.attributes["gen_ai.usage.output_tokens"]
  end

  test "a response without usage yields zero tokens instead of crashing" do
    stub_chat(body: CHAT_RESPONSE.except(:usage))
    reply = SupportAssistant::AskAi.new.call(question: "q", docs: "d")
    assert_equal 0, reply.input_tokens
    assert_equal 0, reply.output_tokens
  end
end
