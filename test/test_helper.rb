ENV["RAILS_ENV"] ||= "test"
# Stop OpenTelemetry from exporting over the network in tests; test/support/otel_helper.rb
# attaches in-memory exporters instead.
ENV["OTEL_TRACES_EXPORTER"] = "none"
ENV["OTEL_METRICS_EXPORTER"] = "none"
ENV["OTEL_LOGS_EXPORTER"] = "none"
ENV["OPENAI_API_KEY"] ||= "test-key"
ENV["OPENAI_MODEL"] ||= "test-model"

require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "webmock/minitest"
require_relative "support/otel_helper"

WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # No parallelization: the in-memory OTel exporters are process-global.
    include OtelHelper
    setup { reset_otel }
  end
end
