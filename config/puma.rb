# 10 threads, so customers waiting on a slow AI answer don't queue behind each other.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 10)
threads threads_count, threads_count
port ENV.fetch("PORT", 3000)
