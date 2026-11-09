require "test_helper"

class AskLedgerTest < ActiveSupport::TestCase
  setup { AskLedger.reset! }

  def gave_up_logs
    emitted_logs.select { |l| l.event_name == "app_name.assistant.user_gave_up" }
  end

  test "abandon before the answer completes emits once, when the tokens become known" do
    AskLedger.start("q1", customer_id: "acme", plan: "enterprise")
    assert AskLedger.abandon("q1")
    assert_empty gave_up_logs

    AskLedger.complete("q1", input_tokens: 120, output_tokens: 30)
    assert_equal 1, gave_up_logs.size
    attrs = gave_up_logs.first.attributes
    assert_equal "acme", attrs["app_name.customer.id"]
    assert_equal "enterprise", attrs["app_name.customer.plan"]
    assert_equal 120, attrs["gen_ai.usage.input_tokens"]
    assert_equal 30, attrs["gen_ai.usage.output_tokens"]
  end

  test "abandon after the answer completed emits immediately" do
    AskLedger.start("q2", customer_id: "acme", plan: "enterprise")
    AskLedger.complete("q2", input_tokens: 10, output_tokens: 5)
    assert_empty gave_up_logs
    AskLedger.abandon("q2")
    assert_equal 1, gave_up_logs.size
  end

  test "abandoning twice, or completing twice, never emits a second event" do
    AskLedger.start("q3", customer_id: "acme", plan: "enterprise")
    AskLedger.abandon("q3")
    AskLedger.abandon("q3")
    AskLedger.complete("q3", input_tokens: 1, output_tokens: 1)
    AskLedger.complete("q3", input_tokens: 1, output_tokens: 1)
    assert_equal 1, gave_up_logs.size
  end

  test "a customer who never abandons produces no event" do
    AskLedger.start("q4", customer_id: "acme", plan: "enterprise")
    AskLedger.complete("q4", input_tokens: 1, output_tokens: 1)
    assert_empty gave_up_logs
  end

  test "abandoning an unknown question returns false and emits nothing" do
    assert_equal false, AskLedger.abandon("nope")
    assert_empty gave_up_logs
  end
end
