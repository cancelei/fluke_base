# Puma configuration for Rails 8.0
# This file configures the Puma web server for your Rails application.

# Thread configuration
# Threads handle concurrent requests within each worker process.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)
threads min_threads_count, max_threads_count

# Port configuration
# Default port is 3006 for this project
port ENV.fetch("PORT", 3006)

# Environment configuration
rails_env = ENV.fetch("RAILS_ENV", "development")
environment rails_env

# PID file location
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Worker timeout in development (prevents workers from being killed during debugging)
worker_timeout 3600 if rails_env == "development"

# Worker configuration
# Workers are forked processes that can handle requests in parallel.
# Total concurrency = workers * threads
workers_count = ENV.fetch("WEB_CONCURRENCY", 1).to_i

if workers_count > 1
  workers workers_count

  # Preload the application before forking workers
  # This uses Copy-on-Write to save memory
  preload_app!

  # Disconnect from database before forking
  before_fork do
    ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
  end

  # Reconnect to database after worker boots
  on_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  end
end

# Enable Puma plugins
plugin :tmp_restart

# Run Solid Queue supervisor inside Puma for single-server deployments
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
