# On a slow day, delay the OpenAI request. The delay MUST happen inside the request that
# the OpenTelemetry instrumentation wraps, otherwise the "chat" span (and therefore
# gen_ai.client.inference.duration) would not include it.
#
# Initializers run in filename order, so this "01_" file is prepended to OpenAI::Client
# before opentelemetry.rb installs the instrumentation. The instrumentation's patch is
# prepended later, so it sits outside this module and its span wraps the sleep.
module SlowDayDelay
  def request(req)
    sleep(SlowDay.extra_seconds) if SlowDay.on?
    super
  end
end

OpenAI::Client.prepend(SlowDayDelay)
