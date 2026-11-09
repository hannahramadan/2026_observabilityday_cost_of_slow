class SupportAssistant
  # Step 2: send the question to the outside AI provider.
  # There is deliberately no hand-written span here: opentelemetry-instrumentation-openai
  # wraps the client call and records the "chat" span with gen_ai.* attributes.
  class AskAi
    Reply = Struct.new(:text, :input_tokens, :output_tokens, keyword_init: true)

    SYSTEM_PROMPT = "You are a concise support assistant. Answer in one or two sentences " \
                    "using only the help docs provided.".freeze

    # max_retries: 0 so a slow day is one slow call, not three retried ones.
    def initialize(client: OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"), max_retries: 0, timeout: 60))
      @client = client
    end

    def call(question:, docs:)
      response = @client.chat.completions.create(
        model: ENV.fetch("OPENAI_MODEL"),
        max_completion_tokens: 150,
        messages: [
          { role: :system, content: SYSTEM_PROMPT },
          { role: :user, content: "Help docs:\n#{docs}\n\nQuestion: #{question}" }
        ]
      )
      usage = response.usage
      Reply.new(
        text: response.choices.first.message.content.to_s,
        input_tokens: (usage&.prompt_tokens).to_i,
        output_tokens: (usage&.completion_tokens).to_i
      )
    end
  end
end
