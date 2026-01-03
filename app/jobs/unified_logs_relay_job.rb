# frozen_string_literal: true

require "net/http"
require "json"

# Background job that connects to flukebase_connect for log streaming.
# Uses HTTP polling for reliability, with WebSocket support for real-time updates.
class UnifiedLogsRelayJob < ApplicationJob
  queue_as :default

  FLUKEBASE_WS_URL = ENV.fetch("FLUKEBASE_WS_URL", "ws://localhost:8766/ws/logs")
  FLUKEBASE_HTTP_URL = ENV.fetch("FLUKEBASE_HTTP_URL", "http://localhost:8766")
  RELAY_LOCK_KEY = "unified_logs_relay_active"
  RELAY_LOCK_TTL = 5.minutes
  POLL_INTERVAL = 2.seconds

  def perform(use_websocket: false)
    # Ensure only one relay job runs at a time
    return if already_running?

    acquire_lock

    Rails.logger.info "[UnifiedLogsRelayJob] Starting log relay (websocket: #{use_websocket})"

    begin
      if use_websocket && websocket_available?
        stream_via_websocket
      else
        poll_for_logs
      end
    rescue StandardError => e
      Rails.logger.error "[UnifiedLogsRelayJob] Relay error: #{e.message}"
    ensure
      release_lock
      Rails.logger.info "[UnifiedLogsRelayJob] Log relay stopped"
    end
  end

  private

  def already_running?
    Rails.cache.read(RELAY_LOCK_KEY).present?
  end

  def acquire_lock
    Rails.cache.write(RELAY_LOCK_KEY, Process.pid, expires_in: RELAY_LOCK_TTL)
  end

  def release_lock
    Rails.cache.delete(RELAY_LOCK_KEY)
  end

  def websocket_available?
    defined?(Faye::WebSocket) && defined?(EventMachine)
  end

  # Stream logs via WebSocket for real-time updates
  def stream_via_websocket
    require "faye/websocket"
    require "eventmachine"

    EM.run do
      ws = Faye::WebSocket::Client.new(FLUKEBASE_WS_URL)

      ws.on :open do |_event|
        Rails.logger.info "[UnifiedLogsRelayJob] WebSocket connected to #{FLUKEBASE_WS_URL}"
      end

      ws.on :message do |event|
        handle_websocket_message(event.data)
      end

      ws.on :close do |event|
        Rails.logger.info "[UnifiedLogsRelayJob] WebSocket closed: #{event.code} - #{event.reason}"
        EM.stop
        # Re-enqueue to reconnect
        self.class.perform_later(use_websocket: true) if has_active_subscribers?
      end

      ws.on :error do |event|
        Rails.logger.error "[UnifiedLogsRelayJob] WebSocket error: #{event.message}"
      end

      # Periodic lock refresh
      EM.add_periodic_timer(60) { acquire_lock }

      # Stop after 5 minutes to allow job restart
      EM.add_timer(300) do
        Rails.logger.info "[UnifiedLogsRelayJob] Stopping WebSocket relay for restart"
        ws.close
      end
    end
  end

  def handle_websocket_message(data)
    message = JSON.parse(data)

    case message["type"]
    when "log_entry"
      broadcast_log_entry(message["data"])
    when "heartbeat", "pong"
      # Keep-alive, do nothing
    when "connected"
      Rails.logger.info "[UnifiedLogsRelayJob] WebSocket confirmed connected"
    else
      Rails.logger.debug "[UnifiedLogsRelayJob] Unknown message type: #{message['type']}"
    end
  rescue JSON::ParserError => e
    Rails.logger.warn "[UnifiedLogsRelayJob] Invalid JSON from WebSocket: #{e.message}"
  end

  # Poll for logs via HTTP (fallback method)
  def poll_for_logs
    last_timestamp = nil
    loop_count = 0
    max_loops = 150 # Run for about 5 minutes then let job restart

    while loop_count < max_loops
      begin
        # Refresh lock
        acquire_lock

        # Fetch recent logs from flukebase_connect HTTP API
        logs = fetch_recent_logs(since: last_timestamp)

        if logs.any?
          logs.each do |entry|
            broadcast_log_entry(entry)
          end

          # Update last timestamp for next poll
          last_timestamp = logs.last["timestamp"]
        end
      rescue StandardError => e
        Rails.logger.error "[UnifiedLogsRelayJob] Poll error: #{e.message}"
      end

      sleep POLL_INTERVAL
      loop_count += 1
    end

    # Re-enqueue to continue polling
    self.class.perform_later if has_active_subscribers?
  end

  def fetch_recent_logs(since: nil)
    uri = URI("#{FLUKEBASE_HTTP_URL}/api/v1/logs/recent")
    params = { limit: 50 }
    params[:since] = since if since.present?
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)["entries"] || []
    else
      Rails.logger.warn "[UnifiedLogsRelayJob] HTTP #{response.code}: #{response.message}"
      []
    end
  rescue StandardError => e
    Rails.logger.warn "[UnifiedLogsRelayJob] Failed to fetch logs: #{e.message}"
    []
  end

  def broadcast_log_entry(entry)
    UnifiedLogsChannel.broadcast_log(entry)
  end

  def has_active_subscribers?
    # Check if there are any active subscriptions
    # This is a simplified check - in production you'd track subscriptions more precisely
    true
  end
end
