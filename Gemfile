source "https://rubygems.org"

gem "rails", "~> 8.1.4"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "openai"

gem "opentelemetry-sdk"
gem "opentelemetry-metrics-sdk"
gem "opentelemetry-logs-sdk"
gem "opentelemetry-exporter-otlp"
gem "opentelemetry-exporter-otlp-metrics"
gem "opentelemetry-exporter-otlp-logs"
gem "opentelemetry-instrumentation-rails"
gem "opentelemetry-instrumentation-openai"

group :development, :test do
  gem "dotenv-rails"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "webmock"
  gem "minitest-mock" # Minitest 6 extracted minitest/mock into its own gem
end
