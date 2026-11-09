class SupportAssistant
  # Step 3: tidy the answer for the chat window. Own span: "format answer".
  class FormatAnswer
    def call(text)
      TRACER.in_span("format answer") do
        sleep 0.05 # pretend work
        text.strip.gsub(/\s+/, " ")
      end
    end
  end
end
