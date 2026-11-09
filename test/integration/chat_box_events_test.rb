require "test_helper"

class ChatBoxEventsTest < ActionDispatch::IntegrationTest
  CHAT = {
    id: "c1", object: "chat.completion", created: 1, model: "test-model",
    choices: [{ index: 0, message: { role: "assistant", content: "Open Settings." }, finish_reason: "stop" }],
    usage: { prompt_tokens: 120, completion_tokens: 30, total_tokens: 150 }
  }.freeze

  setup do
    AskLedger.reset!
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: CHAT.to_json, headers: { "Content-Type" => "application/json" })
  end

  def events(name)
    emitted_logs.select { |l| l.event_name == name }
  end

  test "abandoning after the answer arrived reports the tokens we paid for" do
    post "/v1/ask", params: { customer_id: "acme", question: "q", question_id: "q-1" }, as: :json
    assert_response :success
    post "/v1/asks/q-1/abandon", as: :json
    assert_response :accepted
    gave_up = events("app_name.assistant.user_gave_up")
    assert_equal 1, gave_up.size
    assert_equal 120, gave_up.first.attributes["gen_ai.usage.input_tokens"]
  end

  test "abandoning an unknown question is a 404 with no event" do
    post "/v1/asks/never-asked/abandon", as: :json
    assert_response :not_found
    assert_empty events("app_name.assistant.user_gave_up")
  end

  test "an OpenAI failure still completes the ledger with zero tokens" do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 401, body: { error: { message: "bad key" } }.to_json, headers: { "Content-Type" => "application/json" })
    post "/v1/ask", params: { customer_id: "acme", question: "q", question_id: "q-2" }, as: :json
    assert_response :bad_gateway
    post "/v1/asks/q-2/abandon", as: :json
    gave_up = events("app_name.assistant.user_gave_up")
    assert_equal 1, gave_up.size
    assert_equal 0, gave_up.first.attributes["gen_ai.usage.input_tokens"]
  end

  test "opening a ticket emits ticket_opened with the reason" do
    post "/v1/tickets", params: { customer_id: "initech", reason: "slow_answer" }, as: :json
    assert_response :created
    ticket = events("app_name.support.ticket_opened").first
    assert_equal "initech", ticket.attributes["app_name.customer.id"]
    assert_equal "pro", ticket.attributes["app_name.customer.plan"]
    assert_equal "slow_answer", ticket.attributes["app_name.ticket.reason"]
  end

  test "a ticket with an invalid reason or unknown customer is rejected and emits nothing" do
    post "/v1/tickets", params: { customer_id: "acme", reason: "because" }, as: :json
    assert_response :unprocessable_entity
    post "/v1/tickets", params: { customer_id: "nobody", reason: "slow_answer" }, as: :json
    assert_response :unprocessable_entity
    assert_empty events("app_name.support.ticket_opened")
  end
end
