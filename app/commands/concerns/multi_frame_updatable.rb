# frozen_string_literal: true

# Provides helpers for updating multiple Turbo Frames in a single response
# DRYs up the repeated multi-frame update patterns found in controllers
module MultiFrameUpdatable
  extend ActiveSupport::Concern

  # Standard time logs page update pattern
  # Updates the common frames used in time log operations
  #
  # @param project [Project] The current project
  # @param milestones_pending [ActiveRecord::Relation] Milestones pending confirmation
  # @param current_log [TimeLog, nil] Currently active time log
  # @param owner [Boolean] Whether current user owns the project
  def update_time_logs_frames(project:, milestones_pending:, current_log: nil, owner:)
    turbo_streams << turbo_stream.update(
      "pending_confirmation_section",
      partial: "time_logs/pending_confirmation_section",
      locals: {
        milestones_pending_confirmation: milestones_pending,
        project: project,
        owner: owner
      }
    )

    turbo_streams << turbo_stream.update(
      "remaining_time_progress",
      partial: "remaining_time_progress",
      locals: {
        project: project,
        current_log: current_log,
        owner: owner,
        project_wide: true
      }
    )

    turbo_streams << turbo_stream.update(
      "milestone_bar_container",
      partial: "shared/milestone_bar"
    )

    turbo_streams << turbo_stream.update(
      "context_milestones_list",
      partial: "shared/context_milestones_dropdown"
    )
  end

  # Replace a specific milestone row
  #
  # @param milestone [Milestone] The milestone to update
  # @param project [Project] The project
  # @param active_log [TimeLog, nil] Active time log for this milestone
  def update_milestone_row(milestone:, project:, active_log: nil)
    turbo_streams << turbo_stream.replace(
      "milestone_#{milestone.id}",
      partial: "time_logs/milestone_row",
      locals: {
        milestone: milestone,
        project: project,
        active_log: active_log
      }
    )
  end

  # Update the manual time log form
  #
  # @param time_log [TimeLog] The time log (can be new or with errors)
  # @param milestones [ActiveRecord::Relation] Available milestones
  def update_manual_form(time_log:, milestones:)
    turbo_streams << turbo_stream.update(
      "manual_time_log_form",
      partial: "time_logs/manual_form",
      locals: {
        time_log_manual: time_log,
        milestones: milestones
      }
    )
  end

  # Update the AI suggestion container for milestones
  #
  # @param enhancement [MilestoneEnhancement, OpenStruct] The enhancement data
  # @param milestone [Milestone] The milestone being enhanced
  def update_ai_suggestion(enhancement:, milestone:)
    turbo_streams << turbo_stream.update(
      "ai-suggestion-container",
      partial: "milestones/ai_suggestion",
      locals: {
        enhancement: enhancement,
        milestone: milestone
      }
    )
  end

  # Clear a frame's content
  #
  # @param target_id [String] The ID of the frame to clear
  def clear_frame(target_id)
    turbo_streams << turbo_stream.update(target_id, "")
  end

  # Replace a frame's content with a partial
  #
  # @param target_id [String] The ID of the frame
  # @param partial [String] The partial path
  # @param locals [Hash] Local variables for the partial
  def replace_frame(target_id, partial:, locals: {})
    turbo_streams << turbo_stream.replace(target_id, partial: partial, locals: locals)
  end

  # Update a frame's content with a partial
  #
  # @param target_id [String] The ID of the frame
  # @param partial [String] The partial path
  # @param locals [Hash] Local variables for the partial
  def update_frame(target_id, partial:, locals: {})
    turbo_streams << turbo_stream.update(target_id, partial: partial, locals: locals)
  end

  # Append content to a frame
  #
  # @param target_id [String] The ID of the frame
  # @param partial [String] The partial path
  # @param locals [Hash] Local variables for the partial
  def append_to_frame(target_id, partial:, locals: {})
    turbo_streams << turbo_stream.append(target_id, partial: partial, locals: locals)
  end
end
