# Puma application server configurations

# Configure the thread pool size per worker process.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Specifies the port Puma will bind to for incoming web traffic (default is 3000).
port ENV.fetch("PORT", 3000)

# Enables restarting the server via the `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue background worker supervisor inside Puma in single-server environments.
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# Specifies the PID file path to manage the server process status.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
