# Remembers, per question, who asked, whether they left, and how many tokens the answer
# cost, so that "the customer gave up" can be reported with the tokens we already paid for.
#
# The chat box sends the abandon call while the OpenAI request is still running, so
# either order can happen: abandon-then-complete, or complete-then-abandon. The event is
# reported exactly once, as soon as both facts are known. In-memory only: it resets on
# restart and is not shared between processes, which is fine for a demo.
class AskLedger
  STORE = ActiveSupport::Cache::MemoryStore.new(expires_in: 1.hour)
  LOCK = Mutex.new

  class << self
    def start(id, customer_id:, plan:)
      LOCK.synchronize do
        STORE.write(id, { customer_id: customer_id, plan: plan, abandoned: false, tokens: nil, reported: false })
      end
    end

    def complete(id, input_tokens:, output_tokens:)
      update(id) { |entry| entry[:tokens] = { input: input_tokens, output: output_tokens } }
    end

    # Returns false if the question is unknown.
    def abandon(id)
      update(id) { |entry| entry[:abandoned] = true }
    end

    def reset!
      STORE.clear
    end

    private

    def update(id)
      LOCK.synchronize do
        entry = STORE.read(id)
        return false unless entry

        yield entry
        report_gave_up(entry)
        STORE.write(id, entry)
        true
      end
    end

    def report_gave_up(entry)
      return unless entry[:abandoned] && entry[:tokens] && !entry[:reported]

      OpenTelemetry.logger_provider.logger(name: "support_assistant").on_emit(
        timestamp: Time.now,
        event_name: "app_name.assistant.user_gave_up",
        attributes: {
          "app_name.customer.id" => entry[:customer_id],
          "app_name.customer.plan" => entry[:plan],
          "gen_ai.usage.input_tokens" => entry[:tokens][:input],
          "gen_ai.usage.output_tokens" => entry[:tokens][:output],
          # Also a plain attribute, so LogQL can filter on it however the backend maps event_name.
          "event.name" => "app_name.assistant.user_gave_up"
        }
      )
      entry[:reported] = true
    end
  end
end
