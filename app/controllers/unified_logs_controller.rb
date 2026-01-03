# frozen_string_literal: true

# Controller for the unified logs dashboard
#
# Displays real-time logs from flukebase_connect MCP server including:
# - MCP tool call logs
# - Container stdout/stderr logs
# - Application logs (GitHub Actions, etc.)
#
class UnifiedLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: %i[index export]
  before_action :set_sandbox, only: %i[index export]

  def index
    @log_types = log_type_options
    @log_levels = log_level_options
    @sandboxes = available_sandboxes

    # WebSocket URL for client connection
    @ws_url = build_websocket_url

    respond_to do |format|
      format.html
      format.json { render json: index_json_response }
    end
  end

  def export
    logs = fetch_logs_for_export

    respond_to do |format|
      format.json do
        send_data logs.to_json,
                  filename: export_filename("json"),
                  type: "application/json"
      end
      format.csv do
        send_data logs_to_csv(logs),
                  filename: export_filename("csv"),
                  type: "text/csv"
      end
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id]) if params[:project_id].present?
  end

  def set_sandbox
    @sandbox_id = params[:sandbox_id]
  end

  def log_type_options
    [
      { value: "mcp", label: "MCP Tools", icon: "command-line", color: "primary" },
      { value: "container", label: "Container", icon: "cube", color: "secondary" },
      { value: "application", label: "Application", icon: "document-text", color: "accent" }
    ]
  end

  def log_level_options
    [
      { value: "trace", label: "Trace", color: "base-content/50" },
      { value: "debug", label: "Debug", color: "info" },
      { value: "info", label: "Info", color: "success" },
      { value: "warn", label: "Warn", color: "warning" },
      { value: "error", label: "Error", color: "error" },
      { value: "fatal", label: "Fatal", color: "error" }
    ]
  end

  def available_sandboxes
    FlukebaseConnect::Client.get_sandboxes
  end

  def build_websocket_url
    # ActionCable WebSocket URL with subscription params
    base_url = ENV.fetch("ACTION_CABLE_URL", nil) || request.base_url.sub("http", "ws")
    "#{base_url}/cable"
  end

  def index_json_response
    {
      log_types: @log_types,
      log_levels: @log_levels,
      sandboxes: @sandboxes,
      ws_url: @ws_url,
      project_id: @project&.id,
      sandbox_id: @sandbox_id
    }
  end

  def fetch_logs_for_export
    limit = [params[:limit].to_i, 10_000].min
    limit = 1000 if limit <= 0

    FlukebaseConnect::Client.get_logs(limit: limit, filter: {
      project_id: @project&.id,
      sandbox_id: @sandbox_id
    }.compact)
  end

  def logs_to_csv(logs)
    require "csv"

    CSV.generate(headers: true) do |csv|
      csv << %w[timestamp type level source message sandbox_id]

      logs.each do |log|
        csv << [
          log["timestamp"],
          log.dig("source", "type"),
          log["level"],
          log.dig("source", "agent_id") || log.dig("source", "container_name"),
          log["message"],
          log.dig("source", "sandbox_id")
        ]
      end
    end
  end

  def export_filename(extension)
    parts = ["unified_logs"]
    parts << @project.slug if @project
    parts << @sandbox_id if @sandbox_id
    parts << Time.current.strftime("%Y%m%d_%H%M%S")
    "#{parts.join('_')}.#{extension}"
  end
end
