require_relative "chat_box"

module Demo
  # Sends `count` questions from random customers, `concurrency` at a time.
  class Traffic
    QUESTIONS = [
      "How do I reset my password?", "How can I invite a teammate?",
      "Where do I export my data?", "How do I change my plan?"
    ].freeze

    def self.run(count:, concurrency: 5, base_url: ENV.fetch("BASE_URL", "http://localhost:3000"))
      customers = Rails.configuration.x.customers.keys.map(&:to_s)
      chat_box = ChatBox.new(base_url: base_url, business: Rails.configuration.x.business)
      work = Queue.new
      count.times { work << [customers.sample, QUESTIONS.sample] }
      outcomes = Queue.new

      Array.new(concurrency) do
        Thread.new do
          loop do
            customer, question = work.pop(true)
            outcomes << chat_box.ask(customer, question)
          rescue ThreadError
            break
          end
        end
      end.each(&:join)

      tally = Hash.new(0)
      tally[outcomes.pop] += 1 until outcomes.empty?
      tally
    end
  end
end
