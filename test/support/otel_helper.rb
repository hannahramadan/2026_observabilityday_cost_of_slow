# In-memory OpenTelemetry exporters so tests can assert on what the app emitted.
module OtelHelper
  SPANS   = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
  LOGS    = OpenTelemetry::SDK::Logs::Export::InMemoryLogRecordExporter.new
  METRICS = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new

  OpenTelemetry.tracer_provider.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(SPANS)
  )
  OpenTelemetry.logger_provider.add_log_record_processor(
    OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor.new(LOGS)
  )
  OpenTelemetry.meter_provider.add_metric_reader(METRICS)

  def reset_otel
    SPANS.reset
    LOGS.reset
  end

  def finished_spans = SPANS.finished_spans

  def emitted_logs = LOGS.emitted_log_records

  # Metrics are cumulative across the whole test run, so tests compare a value
  # taken before an action with one taken after it.
  def metric_total(name)
    METRICS.reset
    METRICS.pull
    data = METRICS.metric_snapshots.find { |m| m.name == name }
    return 0 unless data

    data.data_points.sum do |dp|
      dp.is_a?(OpenTelemetry::SDK::Metrics::Aggregation::HistogramDataPoint) ? dp.count : dp.value
    end
  end
end
