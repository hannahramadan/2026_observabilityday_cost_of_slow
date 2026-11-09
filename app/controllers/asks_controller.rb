class AsksController < ApplicationController
  def create
    customer_id = params.require(:customer_id).to_s
    plan = Rails.configuration.x.customers[customer_id.to_sym]
    return render(json: { error: "unknown customer" }, status: :unprocessable_entity) unless plan

    # The chat box generates the question id so it can abandon a question that has not
    # been answered yet.
    question_id = params[:question_id].presence || SecureRandom.uuid
    label_span(customer_id, plan)
    AskLedger.start(question_id, customer_id: customer_id, plan: plan)

    answer = SupportAssistant.new.call(question: params.require(:question))
    AskLedger.complete(question_id, input_tokens: answer.input_tokens, output_tokens: answer.output_tokens)
    render json: { question_id: question_id, answer: answer.text }
  rescue OpenAI::Errors::Error
    # No answer means no tokens were billed; complete the ledger so a later abandon resolves.
    AskLedger.complete(question_id, input_tokens: 0, output_tokens: 0)
    render json: { error: "assistant unavailable" }, status: :bad_gateway
  end

  private

  # Idea 2a: put the customer on the root span, so "the assistant was slow" becomes
  # "Enterprise customers were hit as hard as everyone else".
  def label_span(customer_id, plan)
    span = OpenTelemetry::Instrumentation::Rack.current_span
    span.set_attribute("app_name.customer.id", customer_id)
    span.set_attribute("app_name.customer.plan", plan)
  end
end
