require "test_helper"

class AsksTest < ActionDispatch::IntegrationTest
  CHAT = {
    id: "c1", object: "chat.completion", created: 1, model: "test-model",
    choices: [{ index: 0, message: { role: "assistant", content: "Open Settings, then Security." }, finish_reason: "stop" }],
    usage: { prompt_tokens: 120, completion_tokens: 30, total_tokens: 150 }
  }.freeze

  setup do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: CHAT.to_json, headers: { "Content-Type" => "application/json" })
  end

  teardown { SlowDay.on = false }

  def ask(customer: "acme")
    post "/v1/ask", params: { customer_id: customer, question: "How do I reset my password?" }, as: :json
  end

  test "answers, labels the root span with the customer, and traces each step" do
    ask
    assert_response :success
    assert_equal "Open Settings, then Security.", response.parsed_body["answer"]

    spans = finished_spans
    root = spans.find { |s| s.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID }
    assert_equal "acme", root.attributes["app_name.customer.id"]
    assert_equal "enterprise", root.attributes["app_name.customer.plan"]
    assert_includes spans.map(&:name), "search help docs"
    assert_includes spans.map(&:name), "format answer"
    assert spans.any? { |s| s.attributes["gen_ai.operation.name"] == "chat" }
    assert_equal 1, spans.map(&:trace_id).uniq.size, "all spans should belong to one trace"
  end

  test "an unknown customer is rejected" do
    ask(customer: "nobody")
    assert_response :unprocessable_entity
  end

  test "an OpenAI failure returns 502 and marks the chat span as an error" do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 401, body: { error: { message: "bad key" } }.to_json, headers: { "Content-Type" => "application/json" })
    ask
    assert_response :bad_gateway
    chat = finished_spans.find { |s| s.attributes["gen_ai.operation.name"] == "chat" }
    assert_equal OpenTelemetry::Trace::Status::ERROR, chat.status.code
  end

  test "slow day delays the OpenAI request itself, so the chat span is slow" do
    SlowDay.on = true
    SlowDay.stub(:extra_seconds, 0.3) { ask }
    assert_response :success
    chat = finished_spans.find { |s| s.attributes["gen_ai.operation.name"] == "chat" }
    seconds = (chat.end_timestamp - chat.start_timestamp) / 1_000_000_000.0
    assert_operator seconds, :>=, 0.3
  end

  test "the admin endpoint toggles slow day" do
    post "/admin/slow", params: { on: "true" }
    assert_equal true, response.parsed_body["slow"]
    post "/admin/slow", params: { on: "false" }
    assert_equal false, response.parsed_body["slow"]
  end
end
