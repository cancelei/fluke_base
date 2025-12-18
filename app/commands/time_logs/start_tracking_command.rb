# frozen_string_literal: true

module TimeLogs
  # Command to start tracking time for a milestone
  # Creates a new in-progress time log and updates the UI
  # @return [Dry::Monads::Result] Success(time_log) or Failure(error)
  #
  # Usage in view:
  #   <button data-turbo-command="TimeLogs::StartTrackingCommand#execute"
  #           data-project-id="<%= project.id %>"
  #           data-milestone-id="<%= milestone.id %>">
  #     Start Tracking
  #   </button>
  class StartTrackingCommand < ApplicationCommand
    def execute
      project_id = element_id(:projectId)
      milestone_id = element_id(:milestoneId)

      project = find_project(project_id)
      milestone = project.milestones.find(milestone_id)

      # Check for existing tracking
      if existing_tracking?(project)
        flash_error("You already have a time log in progress.")
        return failure_result(:already_tracking, "You already have a time log in progress.")
      end

      time_log = project.time_logs.new(
        milestone: milestone,
        started_at: Time.current,
        status: "in_progress",
        user: current_user
      )

      if time_log.save
        # Update session tracking state
        set_tracking_milestone(project.id, milestone.id)
        milestone.update!(status: "in_progress")

        # Calculate owner status for rendering
        owner = current_user.id == project.user_id

        # Update milestone row
        update_milestone_row(milestone: milestone, project: project, active_log: time_log)

        # Update current tracking container
        update_frame(
          "current_tracking_container",
          partial: "time_logs/current_tracking",
          locals: { current_log: time_log, project: project }
        )

        # Update milestone bar and navbar
        update_frame("milestone_bar_container", partial: "shared/milestone_bar", locals: {})
        update_frame("context_milestones_list", partial: "shared/context_milestones_dropdown", locals: {})

        # Update remaining time progress
        update_frame(
          "remaining_time_progress",
          partial: "remaining_time_progress",
          locals: { project: project, current_log: time_log, owner: owner }
        )

        flash_notice("Started tracking time for this milestone.")
        Success(time_log)
      else
        flash_error(time_log.errors.full_messages.to_sentence)
        failure_result(:save_failed, time_log.errors.full_messages.to_sentence, errors: time_log.errors)
      end
    rescue ActiveRecord::RecordNotFound => e
      flash_error("Project or milestone not found.")
      failure_result(:not_found, "Project or milestone not found.")
    end

    private

    def existing_tracking?(project)
      scope = TimeLog.in_progress.where(user_id: current_user.id)
      if current_user.respond_to?(:multi_project_tracking) && current_user.multi_project_tracking
        scope = scope.joins(:milestone).where(milestones: { project_id: project.id })
      end
      scope.exists?
    end
  end
end
