require "net/http"
require "json"

# cost = how many x how much each one costs.
# "How many" comes from telemetry (Prometheus and Loki); "how much each" comes from config/business.yml.
#
# Prometheus renames gen_ai.client.inference.duration to gen_ai_client_inference_duration_seconds_*,
# and Loki turns dots in log attributes into underscores.
desc "Print the dollar cost of slow from Prometheus and Loki (how many) x config/business.yml (how much each)"
task dollars: :environment do
  business = Rails.configuration.x.business
  window = ENV.fetch("WINDOW", "6h")
  prometheus_url = ENV.fetch("PROMETHEUS_URL", "http://localhost:9090")
  loki_url = ENV.fetch("LOKI_URL", "http://localhost:3100")

  # Runs an instant query and returns its single number. No data yet means 0, not an error.
  query = lambda do |url, q|
    uri = URI(url)
    uri.query = URI.encode_www_form(query: q)
    sample = JSON.parse(Net::HTTP.get(uri)).dig("data", "result", 0)
    sample ? sample["value"][1].to_f : 0.0
  end
  prometheus = ->(q) { query.call("#{prometheus_url}/api/v1/query", q) }
  loki = ->(q) { query.call("#{loki_url}/loki/api/v1/query", q) }

  # How many (telemetry)
  duration = "gen_ai_client_inference_duration_seconds"
  threshold = business[:too_slow_seconds].to_i
  # All answers minus those inside the bucket whose upper bound is the threshold.
  # "5|5.0" covers either spelling of the le label.
  too_slow_answers = prometheus.call("sum(#{duration}_count) - sum(#{duration}_bucket{le=~\"#{threshold}|#{threshold}.0\"})")
  total_input_tokens = prometheus.call("sum(gen_ai_client_inference_usage_input_tokens_total)")
  total_output_tokens = prometheus.call("sum(gen_ai_client_inference_usage_output_tokens_total)")

  stream = '{service_name="ai-support-assistant"}'
  gave_up = %(#{stream} | event_name="app_name.assistant.user_gave_up")
  slow_answer_tickets = loki.call(%(sum(count_over_time(#{stream} | event_name="app_name.support.ticket_opened" | app_name_ticket_reason="slow_answer" [#{window}]))))
  wasted_input_tokens = loki.call("sum(sum_over_time(#{gave_up} | unwrap gen_ai_usage_input_tokens [#{window}]))")
  wasted_output_tokens = loki.call("sum(sum_over_time(#{gave_up} | unwrap gen_ai_usage_output_tokens [#{window}]))")

  # How much each (business)
  ticket_cost = business[:ticket_cost_usd]
  ticket_rate = business[:ticket_rate_after_give_up]
  prices = business[:token_price_usd_per_million]
  token_cost = ->(input, output) { (input * prices[:input] + output * prices[:output]) / 1_000_000.0 }

  puts <<~REPORT
    Metrics (running totals): how many answers were too slow?
      #{too_slow_answers.round} too-slow answers x #{(ticket_rate * 100).round}% become tickets x $#{ticket_cost} = early estimate $#{(too_slow_answers * ticket_rate * ticket_cost).round(2)}

    Logs (last #{window}): what actually happened?
      #{slow_answer_tickets.round} slow-answer tickets x $#{ticket_cost} = $#{(slow_answer_tickets * ticket_cost).round(2)}
      Tokens paid for answers nobody read: #{wasted_input_tokens.round} in / #{wasted_output_tokens.round} out = $#{token_cost.call(wasted_input_tokens, wasted_output_tokens).round(4)}

    Metrics: total AI token spend, slow or not: #{total_input_tokens.round} in / #{total_output_tokens.round} out = $#{token_cost.call(total_input_tokens, total_output_tokens).round(4)}
  REPORT
end
