require "test_helper"

class GenAiMetricsTest < ActiveSupport::TestCase
  DURATION = "gen_ai.client.inference.duration".freeze
  INPUT    = "gen_ai.client.inference.usage.input_tokens".freeze
  OUTPUT   = "gen_ai.client.inference.usage.output_tokens".freeze

  def finish_span(name, attributes, seconds: 0.02)
    OpenTelemetry.tracer_provider.tracer("test").in_span(name, attributes: attributes) { sleep seconds }
  end

  CHAT_ATTRS = {
    "gen_ai.operation.name" => "chat", "gen_ai.provider.name" => "openai",
    "gen_ai.request.model" => "test-model",
    "gen_ai.usage.input_tokens" => 120, "gen_ai.usage.output_tokens" => 30
  }.freeze

  test "a finished chat span records duration and token usage" do
    before = [metric_total(DURATION), metric_total(INPUT), metric_total(OUTPUT)]
    finish_span("chat test-model", CHAT_ATTRS)
    assert_equal before[0] + 1, metric_total(DURATION)
    assert_equal before[1] + 120, metric_total(INPUT)
    assert_equal before[2] + 30, metric_total(OUTPUT)
  end

  test "the histogram has a bucket boundary at exactly the too-slow threshold" do
    finish_span("chat test-model", CHAT_ATTRS)
    metric_total(DURATION) # forces a pull into METRICS.metric_snapshots
    data = OtelHelper::METRICS.metric_snapshots.find { |m| m.name == DURATION }
    bounds = data.data_points.first.explicit_bounds.map(&:to_f)
    assert_includes bounds, Rails.configuration.x.business[:too_slow_seconds].to_f
  end

  test "metric attributes carry operation, provider and model; tokens add the modality" do
    finish_span("chat test-model", CHAT_ATTRS)
    metric_total(INPUT)
    data = OtelHelper::METRICS.metric_snapshots.find { |m| m.name == INPUT }
    attrs = data.data_points.first.attributes
    assert_equal "chat", attrs["gen_ai.operation.name"]
    assert_equal "openai", attrs["gen_ai.provider.name"]
    assert_equal "text", attrs["gen_ai.token.modality"]
  end

  test "a chat span without usage records zero tokens but still records duration" do
    before = [metric_total(DURATION), metric_total(INPUT)]
    finish_span("chat test-model", CHAT_ATTRS.except("gen_ai.usage.input_tokens", "gen_ai.usage.output_tokens"))
    assert_equal before[0] + 1, metric_total(DURATION)
    assert_equal before[1], metric_total(INPUT)
  end

  test "spans that are not chat operations produce no GenAI metrics" do
    before = metric_total(DURATION)
    finish_span("search help docs", {})
    finish_span("POST /v1/ask", { "http.request.method" => "POST" })
    assert_equal before, metric_total(DURATION)
  end
end
