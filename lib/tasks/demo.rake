require "net/http"

namespace :demo do
  def run_traffic(count)
    require Rails.root.join("lib/demo/traffic")
    tally = Demo::Traffic.run(count: count)
    puts "Done: #{tally.inspect}"
  end

  def set_slow_day(on)
    base = ENV.fetch("BASE_URL", "http://localhost:3000")
    Net::HTTP.post(URI("#{base}/admin/slow?on=#{on}"), "")
  end

  desc "Send COUNT questions from pretend customers on a normal day (default 20)"
  task :normal, [:count] => :environment do |_task, args|
    run_traffic(Integer(args[:count] || 20))
  end

  desc "Same as demo:normal, but the AI provider is having a slow day"
  task :slow, [:count] => :environment do |_task, args|
    set_slow_day(true)
    begin
      run_traffic(Integer(args[:count] || 20))
    ensure
      set_slow_day(false)
    end
  end
end
