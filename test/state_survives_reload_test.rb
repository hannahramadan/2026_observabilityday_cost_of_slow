require "test_helper"

# In development Rails reloads everything under app/ whenever a file is saved. SlowDay's flag
# and AskLedger's store are in-memory demo state, so a reload would silently switch slow day
# off and drop in-flight abandons. They must live in an autoload-once directory (never reloaded).
class StateSurvivesReloadTest < ActiveSupport::TestCase
  ONCE_DIRS = Rails.autoloaders.once.dirs.map(&:to_s)

  %w[SlowDay AskLedger].each do |name|
    test "#{name} lives in an autoload-once directory, so code reloading cannot reset it" do
      Object.const_get(name) # trigger the autoload so the real defining file is recorded
      file = Object.const_source_location(name).first
      assert ONCE_DIRS.any? { |dir| file.start_with?("#{dir}/") },
             "#{name} is defined in #{file}, which is reloadable; autoload-once dirs: #{ONCE_DIRS.inspect}"
    end
  end
end
