# Process-wide "the AI provider is having a bad day" switch. The delay itself is applied
# inside the OpenAI request by config/initializers/01_slow_day.rb.
module SlowDay
  FLAG = Concurrent::AtomicBoolean.new(false)

  def self.on?
    FLAG.true?
  end

  def self.on=(value)
    FLAG.value = value ? true : false
  end

  def self.extra_seconds
    Rails.configuration.x.business[:slow_day_extra_seconds]
  end
end
