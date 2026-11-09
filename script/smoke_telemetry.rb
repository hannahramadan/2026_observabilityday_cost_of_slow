# Sends one slow trace, one fast chat span (so the histogram has two buckets), and the
# two business events. No OpenAI call is made, so no API key is needed.
tracer = OpenTelemetry.tracer_provider.tracer("smoke")

chat = lambda do |seconds, input, output|
  tracer.in_span(
    "chat smoke-model",
    attributes: {
      "gen_ai.operation.name" => "chat", "gen_ai.provider.name" => "openai",
      "gen_ai.request.model" => "smoke-model",
      "gen_ai.usage.input_tokens" => input, "gen_ai.usage.output_tokens" => output
    }
  ) { sleep seconds }
end

tracer.in_span("POST /v1/ask", attributes: { "app_name.customer.id" => "acme", "app_name.customer.plan" => "enterprise" }) do
  tracer.in_span("search help docs") { sleep 0.1 }
  chat.call(6.0, 1407, 187)   # slower than the 5s threshold
  tracer.in_span("format answer") { sleep 0.05 }
end
chat.call(0.3, 900, 100)       # a fast one

logger = OpenTelemetry.logger_provider.logger(name: "support_assistant")
logger.on_emit(
  timestamp: Time.now, event_name: "app_name.assistant.user_gave_up",
  attributes: { "app_name.customer.id" => "acme", "app_name.customer.plan" => "enterprise",
                "gen_ai.usage.input_tokens" => 1407, "gen_ai.usage.output_tokens" => 187,
                "event.name" => "app_name.assistant.user_gave_up" }
)
logger.on_emit(
  timestamp: Time.now, event_name: "app_name.support.ticket_opened",
  attributes: { "app_name.customer.id" => "acme", "app_name.customer.plan" => "enterprise",
                "app_name.ticket.reason" => "slow_answer", "event.name" => "app_name.support.ticket_opened" }
)

# Shutting each provider down flushes its pending data (metrics normally export every 60s).
OpenTelemetry.tracer_provider.shutdown
OpenTelemetry.meter_provider.shutdown
OpenTelemetry.logger_provider.shutdown
puts "smoke telemetry sent"
