require "net/http"
require "json"
require "securerandom"

module Demo
  # Plays the customer's chat window. The server can't see a customer leave, so the chat
  # box reports it: if no answer arrives within too_slow_seconds the customer abandons,
  # and may then open a ticket. Satisfied customers send nothing.
  class ChatBox
    def initialize(base_url:, business:, rng: Random.new)
      @base_url = base_url
      @business = business
      @rng = rng
    end

    def ask(customer_id, question)
      question_id = SecureRandom.uuid
      request = Thread.new do
        post("/v1/ask", { customer_id: customer_id, question: question, question_id: question_id })
      end

      response = request.join(@business[:too_slow_seconds])
      if response
        return :failed unless request.value.is_a?(Net::HTTPSuccess)

        open_ticket(customer_id, "answer_not_helpful") if @rng.rand < @business[:ticket_rate_baseline]
        :answered
      else
        post("/v1/asks/#{question_id}/abandon", {})
        open_ticket(customer_id, "slow_answer") if @rng.rand < @business[:ticket_rate_after_give_up]
        request.join # the server still finishes (and pays for) the abandoned answer
        :gave_up
      end
    end

    private

    def open_ticket(customer_id, reason)
      post("/v1/tickets", { customer_id: customer_id, reason: reason })
    end

    def post(path, body)
      uri = URI.join(@base_url, path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 120
      http.post(uri.path, body.to_json, "Content-Type" => "application/json")
    end
  end
end
