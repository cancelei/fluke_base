# frozen_string_literal: true

# Service for loading time logs data for Turbo Stream updates
# Used when switching projects in the context nav to update page content
class TimeLogsDataService < ApplicationService
  def initialize(project, user)
    @project = project
    @user = user
  end

  def call
    return failure_result(:not_found, "Project not found") unless @project

    Success(build_data)
  end

  private

  def build_data
    {
      milestones_locals: milestones_data,
      pending_locals: pending_data,
      completed_locals: completed_data,
      tracking_locals: tracking_data,
      progress_locals: progress_data
    }
  end

  def milestones_data
    {
      milestones:,
      project: @project
    }
  end

  def pending_data
    {
      milestones_pending_confirmation:,
      project: @project,
      owner: owner?
    }
  end

  def completed_data
    {
      time_logs_completed:,
      project: @project,
      owner: owner?
    }
  end

  def tracking_data
    {
      current_log: current_tracking_log,
      project: @project
    }
  end

  def progress_data
    {
      project: @project,
      current_log: current_tracking_log,
      owner: owner?,
      project_wide: true
    }
  end

  def owner?
    @owner ||= @user.id == @project.user_id
  end

  def milestones
    @milestones ||= if owner?
                      @project.milestones
    else
                      Milestone.where(id: accessible_milestone_ids)
    end
  end

  def milestones_pending_confirmation
    @milestones_pending_confirmation ||= milestones
                                           .includes(:time_logs)
                                           .where(status: "in_progress", time_logs: { status: "completed" })
  end

  def time_logs_completed
    @time_logs_completed ||= milestones
                               .includes(:time_logs)
                               .where(status: Milestone::COMPLETED, time_logs: { status: "completed" })
  end

  def current_tracking_log
    @current_tracking_log ||= @project.time_logs
                                      .where(user_id: @user.id)
                                      .in_progress
                                      .last
  end

  def accessible_milestone_ids
    @project.agreements
            .joins(:agreement_participants)
            .where(agreement_participants: { user_id: @user.id })
            .pluck(:milestone_ids)
            .flatten
  end
end
