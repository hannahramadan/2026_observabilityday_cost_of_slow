# OpenTelemetry setup. Exporter endpoints come from the standard OTEL_* environment
# variables (see .env.example); signals default to OTLP over HTTP.
require Rails.root.join("lib/otel/gen_ai_metrics_span_processor")

OpenTelemetry::SDK.configure do |c|
  c.service_name = "ai-support-assistant"
  # Turn on every installed instrumentation. The ones this demo relies on:
  #   Rack       creates the root (server) span per request
  #   ActionPack names it after the Rails route/controller
  #   OpenAI     the "chat" span with gen_ai.* attributes
  c.use_all
end

# Idea 1 (metrics): put a histogram bucket boundary at the threshold the business cares
# about. The GenAI convention's recommended boundaries jump from 2.56s to 5.12s, so
# "answers over 5 seconds" could not be counted exactly. This one View fixes that.
# The 5 matches too_slow_seconds in config/business.yml; change both together.
# It must be registered before the instrument is created (next block).
OpenTelemetry.meter_provider.add_view(
  "gen_ai.client.inference.duration",
  type: :histogram,
  aggregation: OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(
    boundaries: [0.5, 1, 2, 3, 5, 8, 13]
  )
)

# STOPGAP: derive the GenAI metrics from finished chat spans (see the class comment).
OpenTelemetry.tracer_provider.add_span_processor(Otel::GenAiMetricsSpanProcessor.new)

# Idea 3 (logs): business events are emitted straight through the OTel Logs API
# (logger.on_emit with an event_name); see TicketsController and AskLedger.
