require "test_helper"
require Rails.root.join("lib/demo/chat_box")

class ChatBoxTest < ActiveSupport::TestCase
  BASE = "http://chat.test".freeze
  BUSINESS = { too_slow_seconds: 0.1, ticket_rate_baseline: 0.03, ticket_rate_after_give_up: 0.30 }.freeze
  FakeRng = Struct.new(:value) { def rand = value }

  def chat_box(rng_value)
    Demo::ChatBox.new(base_url: BASE, business: BUSINESS, rng: FakeRng.new(rng_value))
  end

  def stub_ask(delay: 0)
    stub_request(:post, "#{BASE}/v1/ask").to_return do |_request|
      sleep delay
      { status: 200, body: { answer: "ok" }.to_json }
    end
  end

  def ticket_reasons
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys
      .select { |sig| sig.uri.to_s.end_with?("/v1/tickets") }
      .map { |sig| JSON.parse(sig.body)["reason"] }
  end

  setup do
    stub_request(:post, %r{#{BASE}/v1/asks/.+/abandon}).to_return(status: 202)
    stub_request(:post, "#{BASE}/v1/tickets").to_return(status: 201)
  end

  test "a prompt answer from a satisfied customer sends nothing else" do
    stub_ask
    assert_equal :answered, chat_box(0.99).ask("acme", "q")
    assert_not_requested :post, %r{/abandon}
    assert_not_requested :post, "#{BASE}/v1/tickets"
  end

  test "a prompt answer can still lead to a not-helpful ticket at the baseline rate" do
    stub_ask
    assert_equal :answered, chat_box(0.0).ask("acme", "q")
    assert_equal ["answer_not_helpful"], ticket_reasons
  end

  test "a customer who waits too long abandons, and may then open a slow_answer ticket" do
    stub_ask(delay: 0.4)
    assert_equal :gave_up, chat_box(0.0).ask("acme", "q")
    assert_requested :post, %r{/v1/asks/.+/abandon}, times: 1
    assert_equal ["slow_answer"], ticket_reasons
  end

  test "a customer who abandons does not always open a ticket" do
    stub_ask(delay: 0.4)
    assert_equal :gave_up, chat_box(0.99).ask("acme", "q")
    assert_requested :post, %r{/v1/asks/.+/abandon}, times: 1
    assert_not_requested :post, "#{BASE}/v1/tickets"
  end

  test "a server error is reported as failed, not as a satisfied customer" do
    stub_request(:post, "#{BASE}/v1/ask").to_return(status: 502, body: "{}")
    assert_equal :failed, chat_box(0.99).ask("acme", "q")
  end
end
