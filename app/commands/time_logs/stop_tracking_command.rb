# frozen_string_literal: true

module TimeLogs
  # Command to stop tracking time for a milestone
  # Completes the current time log and updates the UI
  # @return [Dry::Monads::Result] Success(time_log) or Failure(error)
  #
  # Usage in view:
  #   <button data-turbo-command="TimeLogs::StopTrackingCommand#execute"
  #           data-project-id="<%= project.id %>"
  #           data-milestone-id="<%= milestone.id %>">
  #     Stop Tracking
  #   </button>
  class StopTrackingCommand < ApplicationCommand
    def execute
      project_id = element_id(:projectId)
      milestone_id = element_id(:milestoneId)

      project = find_project(project_id)

      # Find the active time log
      time_log = project.time_logs.in_progress.find_by!(
        milestone_id: milestone_id,
        user_id: current_user.id
      )

      if time_log.complete!
        # Clear session tracking state
        clear_tracking_milestone(project.id)

        # Calculate owner status for rendering
        owner = current_user.id == project.user_id
        milestones_pending = load_pending_milestones(project, owner)

        # Update milestone row
        update_milestone_row(milestone: time_log.milestone, project: project, active_log: nil)

        # Clear current tracking container
        clear_frame("current_tracking_container")

        # Update milestone bar and navbar
        update_frame("milestone_bar_container", partial: "shared/milestone_bar", locals: {})
        update_frame("context_milestones_list", partial: "shared/context_milestones_dropdown", locals: {})

        # Update pending confirmation section
        update_frame(
          "pending_confirmation_section",
          partial: "time_logs/pending_confirmation_section",
          locals: {
            milestones_pending_confirmation: milestones_pending,
            project: project,
            owner: owner
          }
        )

        # Update remaining time progress
        update_frame(
          "remaining_time_progress",
          partial: "remaining_time_progress",
          locals: { project: project, current_log: nil, owner: owner, project_wide: true }
        )

        flash_notice("Stopped tracking time.")
        Success(time_log)
      else
        flash_error(time_log.errors.full_messages.to_sentence)
        failure_result(:complete_failed, time_log.errors.full_messages.to_sentence, errors: time_log.errors)
      end
    rescue ActiveRecord::RecordNotFound
      flash_error("Active time log not found.")
      failure_result(:not_found, "Active time log not found.")
    end

    private

    def load_pending_milestones(project, owner)
      milestones = if owner
        project.milestones
      else
        Milestone.where(
          id: project.agreements
            .joins(:agreement_participants)
            .where(agreement_participants: { user_id: current_user.id })
            .pluck(:milestone_ids)
            .flatten
        )
      end

      milestones
        .includes(:time_logs)
        .where(status: "in_progress", time_logs: { status: "completed" })
    end
  end
end
