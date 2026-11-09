module Otel
  # STOPGAP. opentelemetry-instrumentation-openai 0.1.0 creates spans but emits no metrics.
  # This span processor reads each finished "chat" span and records the standard GenAI
  # client metrics from it, under the exact names in the semantic conventions:
  #   gen_ai.client.inference.duration            (Histogram, s)
  #   gen_ai.client.inference.usage.input_tokens  (Counter, {token})
  #   gen_ai.client.inference.usage.output_tokens (Counter, {token})
  # Delete this file once the instrumentation records them itself, otherwise every call
  # would be counted twice.
  class GenAiMetricsSpanProcessor
    SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS

    METRIC_ATTRIBUTES = %w[
      gen_ai.operation.name gen_ai.provider.name gen_ai.request.model
      gen_ai.response.model error.type server.address server.port
    ].freeze

    def initialize(meter_provider: OpenTelemetry.meter_provider)
      meter = meter_provider.meter("support_assistant.gen_ai_metrics_stopgap")
      @duration = meter.create_histogram(
        "gen_ai.client.inference.duration", unit: "s",
        description: "GenAI client inference operation duration."
      )
      @input_tokens = meter.create_counter(
        "gen_ai.client.inference.usage.input_tokens", unit: "{token}",
        description: "Number of input (prompt) tokens used."
      )
      @output_tokens = meter.create_counter(
        "gen_ai.client.inference.usage.output_tokens", unit: "{token}",
        description: "Number of output (completion) tokens used."
      )
    end

    def on_start(_span, _parent_context); end

    def on_finish(span)
      attributes = span.attributes
      return unless attributes && attributes["gen_ai.operation.name"] == "chat"

      metric_attributes = attributes.slice(*METRIC_ATTRIBUTES)
      @duration.record((span.end_timestamp - span.start_timestamp) / 1_000_000_000.0, attributes: metric_attributes)

      token_attributes = metric_attributes.merge("gen_ai.token.modality" => "text")
      @input_tokens.add(attributes["gen_ai.usage.input_tokens"].to_i, attributes: token_attributes)
      @output_tokens.add(attributes["gen_ai.usage.output_tokens"].to_i, attributes: token_attributes)
    end

    def force_flush(timeout: nil)
      SUCCESS
    end

    def shutdown(timeout: nil)
      SUCCESS
    end
  end
end
