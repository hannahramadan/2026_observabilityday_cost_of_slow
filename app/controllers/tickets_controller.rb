# The chat box calls this when the customer clicks "contact a human".
# A ticket is a business event, not an error: error dashboards never show it.
class TicketsController < ApplicationController
  REASONS = %w[slow_answer answer_not_helpful].freeze

  def create
    customer_id = params.require(:customer_id).to_s
    reason = params.require(:reason).to_s
    plan = Rails.configuration.x.customers[customer_id.to_sym]
    unless plan && REASONS.include?(reason)
      return render(json: { error: "unknown customer or reason" }, status: :unprocessable_entity)
    end

    OpenTelemetry.logger_provider.logger(name: "support_assistant").on_emit(
      timestamp: Time.now,
      event_name: "app_name.support.ticket_opened",
      attributes: {
        "app_name.customer.id" => customer_id,
        "app_name.customer.plan" => plan,
        "app_name.ticket.reason" => reason,
        "event.name" => "app_name.support.ticket_opened"
      }
    )
    head :created
  end
end
