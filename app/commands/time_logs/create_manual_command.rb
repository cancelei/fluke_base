# frozen_string_literal: true

module TimeLogs
  # Command to create a manual time log entry
  # Allows users to log time that was tracked outside the system
  # @return [Dry::Monads::Result] Success(time_log) or Failure(error)
  #
  # Usage in view:
  #   <form data-turbo-command="TimeLogs::CreateManualCommand#execute">
  #     <input type="hidden" name="project_id" data-project-id="<%= project.id %>">
  #     <select name="milestone_id">...</select>
  #     <input name="hours" type="number">
  #     <input name="description" type="text">
  #     <button type="submit">Add Manual Log</button>
  #   </form>
  class CreateManualCommand < ApplicationCommand
    def execute
      project_id = element_data(:projectId) || params[:project_id]
      milestone_id = params.dig(:time_log, :milestone_id) || params[:milestone_id]

      if milestone_id.blank?
        flash_error("Please select a milestone before adding a manual time log.")
        return failure_result(:validation_error, "Please select a milestone before adding a manual time log.")
      end

      project = find_project(project_id)
      milestone = project.milestones.find_by(id: milestone_id)

      if milestone.nil?
        flash_error("Milestone not found. Please select a valid milestone.")
        return failure_result(:not_found, "Milestone not found. Please select a valid milestone.")
      end

      time_log = project.time_logs.new(time_log_params)
      time_log.user = current_user
      time_log.milestone = milestone
      time_log.status = "completed"

      owner = current_user.id == project.user_id
      milestones = load_milestones(project, owner)

      if time_log.save
        milestone.update!(status: "in_progress")
        milestones_pending = load_pending_milestones(project, owner)

        # Update the manual form with a fresh time log
        update_manual_form(time_log: TimeLog.new, milestones:)

        # Update milestone row
        update_milestone_row(milestone:, project:, active_log: nil)

        # Update pending confirmation section
        update_frame(
          "pending_confirmation_section",
          partial: "time_logs/pending_confirmation_section",
          locals: {
            milestones_pending_confirmation: milestones_pending,
            project:,
            owner:
          }
        )

        # Update remaining time progress
        update_frame(
          "remaining_time_progress",
          partial: "remaining_time_progress",
          locals: { project:, current_log: nil, owner:, project_wide: true }
        )

        flash_notice("Time log created successfully.")
        Success(time_log)
      else
        # Show form with errors
        update_manual_form(time_log:, milestones:)
        flash_error(time_log.errors.full_messages.to_sentence)
        failure_result(:save_failed, time_log.errors.full_messages.to_sentence, errors: time_log.errors)
      end
    rescue ActiveRecord::RecordNotFound
      flash_error("Project not found.")
      failure_result(:not_found, "Project not found.")
    end

    private

    def time_log_params
      params.require(:time_log).permit(:started_at, :ended_at, :description, :hours_spent)
    rescue ActionController::ParameterMissing
      {}
    end

    def load_milestones(project, owner)
      if owner
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
    end

    def load_pending_milestones(project, owner)
      load_milestones(project, owner)
        .includes(:time_logs)
        .where(status: "in_progress", time_logs: { status: "completed" })
    end
  end
end
