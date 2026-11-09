# The AI support assistant: search help docs -> ask the AI -> format the answer.
class SupportAssistant
  TRACER = OpenTelemetry.tracer_provider.tracer("support_assistant")

  Answer = Struct.new(:text, :input_tokens, :output_tokens, keyword_init: true)

  def initialize(search: SearchDocs.new, ask_ai: AskAi.new, format: FormatAnswer.new)
    @search = search
    @ask_ai = ask_ai
    @format = format
  end

  def call(question:)
    docs = @search.call(question)
    reply = @ask_ai.call(question: question, docs: docs)
    Answer.new(text: @format.call(reply.text), input_tokens: reply.input_tokens, output_tokens: reply.output_tokens)
  end
end
