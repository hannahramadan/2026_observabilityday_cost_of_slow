class SupportAssistant
  # Step 1: "search" the help docs. A real system would query a search index; here we
  # pick the doc sharing the most words with the question. Own span: "search help docs".
  class SearchDocs
    def call(question)
      TRACER.in_span("search help docs") do
        words = question.downcase.scan(/\w+/)
        best = Rails.configuration.x.help_docs.max_by do |doc|
          (words & "#{doc[:title]} #{doc[:body]}".downcase.scan(/\w+/)).size
        end
        sleep 0.1 # pretend work, so the span has a visible duration
        "#{best[:title]}: #{best[:body]}"
      end
    end
  end
end
