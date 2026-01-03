# frozen_string_literal: true

# Controller for the Team Board web UI.
# Displays WeDo tasks in a Kanban-style board with real-time updates via ActionCable.
class TeamBoardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_task, only: %i[show update]

  # GET /projects/:project_id/team_board
  # Display the Kanban board with all tasks grouped by status
  def index
    @tasks = @project.wedo_tasks.includes(:assignee, :created_by, :parent_task)

    # Filter by scope if specified
    @tasks = @tasks.for_scope(params[:scope]) if params[:scope].present?

    # Filter by assignee if specified
    @tasks = @tasks.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?

    # Group tasks by status for Kanban columns
    @tasks_by_status = {
      pending: @tasks.pending.root_tasks.by_priority.order(created_at: :desc),
      in_progress: @tasks.in_progress.root_tasks.by_priority.order(updated_at: :desc),
      blocked: @tasks.blocked.root_tasks.by_priority.order(updated_at: :desc),
      completed: @tasks.completed.root_tasks.by_priority.order(completed_at: :desc).limit(20)
    }

    # Stats for the header
    @stats = {
      total: @tasks.root_tasks.count,
      pending: @tasks.pending.root_tasks.count,
      in_progress: @tasks.in_progress.root_tasks.count,
      blocked: @tasks.blocked.root_tasks.count,
      completed: @tasks.completed.root_tasks.count
    }

    # Calculate progress percentage
    @progress = @stats[:total].positive? ? (@stats[:completed].to_f / @stats[:total] * 100).round : 0

    # Get active agent sessions
    @active_agents = @project.agent_sessions.connected.order(last_heartbeat_at: :desc).limit(10)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /projects/:project_id/team_board/:id
  # Show task details (typically in a modal or side panel)
  def show
    respond_to do |format|
      format.html
      format.turbo_stream { render partial: "task_detail", locals: { task: @task } }
    end
  end

  # PATCH/PUT /projects/:project_id/team_board/:id
  # Update a task (status changes, assignment, etc.)
  def update
    @task.updated_by = current_user

    # Append synthesis note if provided
    synthesis_note = params[:synthesis_note] || params.dig(:wedo_task, :synthesis_note)
    @task.append_synthesis_note(synthesis_note) if synthesis_note.present?

    if @task.update(task_params)
      # Refresh stats for turbo stream response
      refresh_stats

      respond_to do |format|
        format.turbo_stream
        format.json { render json: { success: true, task: @task.to_api_hash } }
        format.html { redirect_to project_team_board_index_path(@project), notice: "Task updated successfully." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :show, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @task.errors.full_messages }, status: :unprocessable_entity }
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_project
    @project = current_user.accessible_projects.find { |p| p.id == params[:project_id].to_i } ||
               current_user.projects.friendly.find(params[:project_id])

    redirect_to dashboard_path, alert: "Project not found" unless @project
  end

  def set_task
    @task = @project.wedo_tasks.find_by(task_id: params[:id]) ||
            @project.wedo_tasks.find_by(id: params[:id])

    head :not_found unless @task
  end

  def task_params
    params.require(:wedo_task).permit(:status, :priority, :assignee_id, :description, :due_date)
  end

  def refresh_stats
    tasks = @project.wedo_tasks.includes(:assignee, :created_by, :parent_task)
    @stats = {
      total: tasks.root_tasks.count,
      pending: tasks.pending.root_tasks.count,
      in_progress: tasks.in_progress.root_tasks.count,
      blocked: tasks.blocked.root_tasks.count,
      completed: tasks.completed.root_tasks.count
    }
  end
end
