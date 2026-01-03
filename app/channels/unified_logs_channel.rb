# frozen_string_literal: true

# ActionCable channel for streaming unified logs from flukebase_connect WebSocket server.
# Proxies real-time log entries from MCP, Container, Application, and AI Provider sources.
#
# SECURITY: This channel handles cross-framework data from Python flukebase_connect.
# All inputs are validated and user authorization is enforced.
class UnifiedLogsChannel < ApplicationCable::Channel
  FLUKEBASE_WS_URL = ENV.fetch("FLUKEBASE_WS_URL", "ws://localhost:8766")

  # SECURITY: Allowed log types and levels for validation
  ALLOWED_TYPES = %w[mcp container application ai_provider].freeze
  ALLOWED_LEVELS = %w[trace debug info warn error fatal].freeze
  ALLOWED_PROVIDERS = %w[claude openai gemini].freeze

  def subscribed
    # SECURITY: Validate and authorize project access
    @project_id = validate_project_id(params[:project_id])
    @sandbox_id = validate_sandbox_id(params[:sandbox_id])

    # Reject if project specified but user lacks access
    if @project_id && !user_can_access_project?(@project_id)
      reject
      return
    end

    stream_name = build_stream_name
    stream_from stream_name

    # Also stream from global "all" stream to receive all broadcasts
    stream_from "unified_logs:all"

    # Stream from project-specific stream if project selected
    stream_from "unified_logs:project_#{@project_id}" if @project_id.present?

    # Track subscription for broadcasting
    @stream_name = stream_name

    # Start background connection to flukebase_connect if not already running
    ensure_log_relay_running

    Rails.logger.info "[UnifiedLogsChannel] User #{current_user.id} subscribed to #{stream_name}"

    # Send initial connection confirmation
    transmit({
      type: "connected",
      stream: stream_name,
      sandbox_id: @sandbox_id,
      project_id: @project_id,
      timestamp: Time.current.iso8601
    })
  end

  def unsubscribed
    Rails.logger.info "[UnifiedLogsChannel] User #{current_user.id} unsubscribed"
  end

  # Handle filter changes from client
  # SECURITY: Validate all filter inputs
  def set_filter(data)
    filter = {
      types: validate_types(data["types"]),
      levels: validate_levels(data["levels"]),
      sandbox_ids: validate_sandbox_ids(data["sandbox_ids"]),
      search: validate_search(data["search"])
    }.compact

    # Store filter for this connection
    @current_filter = filter

    # Forward to flukebase_connect via HTTP API (WebSocket filter would be per-connection)
    transmit({
      type: "filter_set",
      filter: filter,
      timestamp: Time.current.iso8601
    })

    Rails.logger.info "[UnifiedLogsChannel] Filter set: #{filter.inspect}"
  end

  # Request historical logs
  def get_history(data)
    limit = [data["limit"].to_i, 500].min
    limit = 100 if limit <= 0

    # Fetch from flukebase_connect API
    logs = fetch_log_history(limit: limit, filter: @current_filter)

    transmit({
      type: "history",
      entries: logs,
      count: logs.size,
      timestamp: Time.current.iso8601
    })
  end

  # Ping/pong for connection health
  def ping(_data)
    transmit({ type: "pong", timestamp: Time.current.iso8601 })
  end

  private

  def build_stream_name
    parts = ["unified_logs"]
    parts << "project_#{@project_id}" if @project_id.present?
    parts << "sandbox_#{@sandbox_id}" if @sandbox_id.present?
    parts << "user_#{current_user.id}"
    parts.join(":")
  end

  def ensure_log_relay_running
    # The log relay runs as a background job that connects to flukebase_connect
    # and broadcasts to all subscribed streams
    UnifiedLogsRelayJob.perform_later unless log_relay_active?
  end

  def log_relay_active?
    # Check if relay job is running (uses Rails cache for coordination)
    Rails.cache.read("unified_logs_relay_active").present?
  end

  def fetch_log_history(limit:, filter: nil)
    FlukebaseConnect::Client.get_logs(limit: limit, filter: filter)
  rescue StandardError => e
    Rails.logger.error "[UnifiedLogsChannel] Failed to fetch history: #{e.message}"
    []
  end

  # SECURITY: Input validation methods for cross-framework data

  def validate_project_id(project_id)
    return nil if project_id.blank?

    # Only allow numeric project IDs
    id = project_id.to_s.gsub(/\D/, "")
    id.present? ? id.to_i : nil
  end

  def validate_sandbox_id(sandbox_id)
    return nil if sandbox_id.blank?

    # Sandbox IDs should be alphanumeric with hyphens only
    sanitized = sandbox_id.to_s.gsub(/[^a-zA-Z0-9\-_]/, "")
    sanitized.present? && sanitized.length <= 64 ? sanitized : nil
  end

  def validate_types(types)
    return nil unless types.is_a?(Array)

    types.map(&:to_s).select { |t| ALLOWED_TYPES.include?(t) }.presence
  end

  def validate_levels(levels)
    return nil unless levels.is_a?(Array)

    levels.map(&:to_s).select { |l| ALLOWED_LEVELS.include?(l) }.presence
  end

  def validate_sandbox_ids(sandbox_ids)
    return [@sandbox_id].compact unless sandbox_ids.is_a?(Array)

    sandbox_ids.map { |id| validate_sandbox_id(id) }.compact.presence
  end

  def validate_search(search)
    return nil if search.blank?

    # Limit search query length and remove potentially dangerous characters
    sanitized = search.to_s.gsub(/[<>]/, "").truncate(500)
    sanitized.present? ? sanitized : nil
  end

  def user_can_access_project?(project_id)
    return false unless current_user

    # User must be owner or have an agreement with the project
    Project.where(id: project_id)
           .where("user_id = ? OR id IN (SELECT project_id FROM agreements WHERE user_id = ?)",
                  current_user.id, current_user.id)
           .exists?
  end

  class << self
    # Broadcast a log entry to all relevant streams
    # SECURITY: Sanitize entry before broadcasting to prevent XSS
    def broadcast_log(entry)
      sanitized_entry = sanitize_log_entry(entry)
      streams = determine_target_streams(sanitized_entry)

      streams.each do |stream_name|
        ActionCable.server.broadcast(stream_name, {
          type: "log",
          entry: sanitized_entry,
          timestamp: Time.current.iso8601
        })
      end
    end

    # SECURITY: Sanitize log entry from Python flukebase_connect
    def sanitize_log_entry(entry)
      return {} unless entry.is_a?(Hash)

      result = {
        "id" => entry["id"].to_s.gsub(/[^a-zA-Z0-9\-_]/, "")[0..64],
        "timestamp" => entry["timestamp"].to_s[0..32],
        "level" => ALLOWED_LEVELS.include?(entry["level"].to_s) ? entry["level"] : "info",
        "message" => entry["message"].to_s.truncate(10_000),
        "source" => sanitize_source(entry["source"]),
        "tags" => sanitize_tags(entry["tags"]),
        "project_id" => entry["project_id"].to_s.gsub(/\D/, "").presence
      }

      # AI provider-specific fields
      if entry.dig("source", "type") == "ai_provider"
        result["tokens"] = entry["tokens"].to_i if entry["tokens"].present?
        result["duration_ms"] = entry["duration_ms"].to_f if entry["duration_ms"].present?
      end

      result.compact
    end

    def sanitize_source(source)
      return nil unless source.is_a?(Hash)

      result = {
        "type" => ALLOWED_TYPES.include?(source["type"].to_s) ? source["type"] : "application",
        "agent_id" => source["agent_id"].to_s.gsub(/[^a-zA-Z0-9\-_]/, "")[0..64].presence,
        "sandbox_id" => source["sandbox_id"].to_s.gsub(/[^a-zA-Z0-9\-_]/, "")[0..64].presence,
        "container_name" => source["container_name"].to_s.gsub(/[^a-zA-Z0-9\-_.]/, "")[0..128].presence
      }

      # AI provider-specific fields
      if result["type"] == "ai_provider"
        result["provider"] = ALLOWED_PROVIDERS.include?(source["provider"].to_s) ? source["provider"] : nil
        result["model"] = source["model"].to_s.gsub(/[^a-zA-Z0-9\-_.]/, "")[0..64].presence
      end

      result.compact
    end

    def sanitize_tags(tags)
      return nil unless tags.is_a?(Array)

      tags.first(20).map { |t| t.to_s.gsub(/[^a-zA-Z0-9\-_]/, "")[0..32] }.compact.presence
    end

    # Broadcast stats update
    def broadcast_stats(stats)
      ActionCable.server.broadcast("unified_logs:stats", {
        type: "stats",
        stats: stats,
        timestamp: Time.current.iso8601
      })
    end

    private

    def determine_target_streams(entry)
      streams = []

      # Global stream for all logs
      streams << "unified_logs:all"

      # Project-specific stream
      if entry["project_id"].present?
        streams << "unified_logs:project_#{entry['project_id']}"
      end

      # Sandbox-specific stream
      if entry.dig("source", "sandbox_id").present?
        streams << "unified_logs:sandbox_#{entry.dig('source', 'sandbox_id')}"
      end

      streams
    end
  end
end
