# frozen_string_literal: true

# ActionCable channel for real-time Team Board task updates.
# Enables bi-directional sync between CLI agents and browser clients.
#
# Subscription requires project access.
# Broadcasts task events to all subscribers of a project.
#
# Events:
#   - task.created: New task created
#   - task.updated: Task details changed
#   - task.status_changed: Task status changed
#   - conflict: Sync conflict detected
#   - sync.response: Response to sync_request
class TeamBoardChannel < ApplicationCable::Channel
  def subscribed
    @project = find_project(params[:project_id])

    unless @project
      reject
      return
    end

    stream_for @project

    Rails.logger.info "[TeamBoardChannel] User #{current_user.id} subscribed to project #{@project.id}"

    # Send initial connection confirmation with current state
    transmit({
      type: "connected",
      project_id: @project.id,
      timestamp: Time.current.iso8601,
      max_version: @project.wedo_tasks.maximum(:version) || 0
    })
  end

  def unsubscribed
    Rails.logger.info "[TeamBoardChannel] User #{current_user&.id} unsubscribed from project #{@project&.id}"
  end

  # Handle task creation from WebSocket client
  # Data: { task_id, description, status?, dependency?, scope?, priority?, tags?, blocked_by?, external_id? }
  def create_task(data)
    task = @project.wedo_tasks.build(
      task_id: data["task_id"],
      description: data["description"],
      status: data["status"] || "pending",
      dependency: data["dependency"] || "AGENT_CAPABLE",
      scope: data["scope"] || "global",
      priority: data["priority"] || "normal",
      tags: data["tags"] || [],
      blocked_by: data["blocked_by"] || [],
      external_id: data["external_id"],
      created_by: current_user,
      updated_by: current_user
    )

    task.append_synthesis_note("Task created via WebSocket", agent_id: data["agent_id"])

    if task.save
      # Model callback broadcasts to all subscribers
      transmit({ type: "task.created.ack", task_id: task.task_id, id: task.id, version: task.version })
    else
      transmit({ type: "error", action: "create_task", message: task.errors.full_messages.join(", ") })
    end
  end

  # Handle task update from WebSocket client
  # Data: { task_id, version?, status?, description?, priority?, synthesis_note?, agent_id? }
  def update_task(data)
    task = @project.wedo_tasks.find_by(task_id: data["task_id"])

    unless task
      transmit({ type: "error", action: "update_task", message: "Task not found: #{data['task_id']}" })
      return
    end

    # Version check for optimistic locking
    client_version = data["version"].to_i
    if client_version.positive? && task.version > client_version
      transmit({
        type: "conflict",
        task_id: task.task_id,
        server_version: task.version,
        client_version: client_version,
        server_task: task.to_api_hash
      })
      return
    end

    task.updated_by = current_user

    # Append synthesis note if provided
    if data["synthesis_note"].present?
      task.append_synthesis_note(data["synthesis_note"], agent_id: data["agent_id"])
    end

    # Build update attributes from allowed fields
    update_attrs = data.slice("status", "description", "priority", "assignee_id",
                              "artifact_path", "remote_url")
                       .compact
                       .transform_keys(&:to_sym)

    # Handle array fields
    update_attrs[:blocked_by] = data["blocked_by"] if data.key?("blocked_by")
    update_attrs[:tags] = data["tags"] if data.key?("tags")

    if task.update(update_attrs)
      transmit({ type: "task.updated.ack", task_id: task.task_id, version: task.version })
    else
      transmit({ type: "error", action: "update_task", message: task.errors.full_messages.join(", ") })
    end
  end

  # Request sync of tasks since a specific version
  # Data: { since_version? }
  def sync_request(data)
    since_version = data["since_version"].to_i

    tasks = @project.wedo_tasks
    tasks = tasks.since_version(since_version) if since_version.positive?

    transmit({
      type: "sync.response",
      tasks: tasks.map(&:to_api_hash),
      max_version: @project.wedo_tasks.maximum(:version) || 0,
      timestamp: Time.current.iso8601
    })
  end

  # Ping for connection health
  def ping(_data)
    transmit({ type: "pong", timestamp: Time.current.iso8601 })
  end

  # Handle agent registration broadcast (FIX-003)
  # Data: { agent_id, agent_name?, is_named_persona? }
  def agent_registered(data)
    TeamBoardChannel.broadcast_to(@project, {
      type: "agent.registered",
      agent: {
        id: data["agent_id"],
        name: data["agent_name"] || data["agent_id"],
        is_named_persona: data["is_named_persona"] || false
      },
      timestamp: Time.current.iso8601
    })

    transmit({ type: "agent.registered.ack", agent_id: data["agent_id"] })
  end

  # Class methods for broadcasting from model callbacks or other controllers
  class << self
    # Broadcast task event to all project subscribers
    # Options:
    #   - agent_id: ID of the agent making the change
    #   - agent_name: Human-readable name of the agent
    #   - include_milestone: Include parent task/milestone context (default: true)
    def broadcast_task_event(project, event_type, task, options = {})
      payload = {
        type: event_type,
        task: task.to_api_hash,
        timestamp: Time.current.iso8601,
        activity: {
          last_activity: Time.current.iso8601,
          event_type: event_type
        }
      }

      # Include agent context if provided
      if options[:agent_id].present?
        payload[:agent] = {
          id: options[:agent_id],
          name: options[:agent_name] || options[:agent_id]
        }
        payload[:activity][:agent_id] = options[:agent_id]
      end

      # Include milestone context (parent task info)
      if options.fetch(:include_milestone, true) && task.parent_task.present?
        milestone = task.parent_task
        payload[:milestone] = {
          id: milestone.id,
          task_id: milestone.task_id,
          description: milestone.description,
          status: milestone.status,
          progress_percent: milestone.progress_percentage,
          subtask_count: milestone.subtasks.count,
          completed_subtask_count: milestone.subtasks.completed.count
        }
      end

      broadcast_to(project, payload)
    end

    # Broadcast agent activity update for team board real-time display
    # Shows which agent is working on what task and their current status
    def broadcast_agent_activity(project, agent_id:, task:, activity_type:, metadata: {})
      broadcast_to(project, {
        type: "agent.activity",
        agent: {
          id: agent_id,
          name: metadata[:agent_name] || agent_id
        },
        task: {
          id: task.id,
          task_id: task.task_id,
          description: task.description,
          status: task.status
        },
        activity: {
          type: activity_type, # started, paused, resumed, completed, blocked
          timestamp: Time.current.iso8601,
          started_at: metadata[:started_at],
          time_spent_minutes: metadata[:time_spent_minutes] || 0
        },
        milestone_id: task.parent_task&.task_id,
        timestamp: Time.current.iso8601
      })
    end

    # Broadcast team board snapshot for initial sync or periodic refresh
    def broadcast_team_board_snapshot(project, agents_tasks_map)
      broadcast_to(project, {
        type: "team_board.snapshot",
        agents: agents_tasks_map.map do |agent_id, tasks|
          {
            id: agent_id,
            tasks: tasks.map do |t|
              {
                task_id: t[:task_id],
                status: t[:status],
                last_activity: t[:last_activity],
                milestone_id: t[:milestone_id]
              }
            end
          }
        end,
        timestamp: Time.current.iso8601
      })
    end

    # Broadcast generic message to project subscribers
    def broadcast_to_project(project, message)
      broadcast_to(project, message.merge(timestamp: Time.current.iso8601))
    end
  end

  private

  def find_project(project_id)
    return nil if project_id.blank?

    project_id = project_id.to_s.gsub(/\D/, "").to_i
    return nil if project_id.zero?

    # Check user has access to this project
    current_user.accessible_projects.find { |p| p.id == project_id }
  end
end
