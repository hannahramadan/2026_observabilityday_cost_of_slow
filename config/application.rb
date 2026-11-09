require_relative "boot"

require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module OtelCostOfSlowRails
  class Application < Rails::Application
    config.load_defaults 8.1
    config.api_only = true

    # lib/otel and lib/demo are required explicitly, not autoloaded.
    config.autoload_lib(ignore: %w[assets tasks otel demo])

    # Business numbers, the customer->plan table and the fake help docs; see config/*.yml.
    config.x.business  = config_for(:business)
    config.x.customers = config_for(:customers)
    config.x.help_docs = config_for(:help_docs)

    # Never reloaded: app/state holds in-memory demo state (the slow-day flag, the abandon
    # ledger) that a development code reload would otherwise silently reset mid-demo.
    config.autoload_once_paths << "#{root}/app/state"
  end
end
