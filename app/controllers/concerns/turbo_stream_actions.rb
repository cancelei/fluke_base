# frozen_string_literal: true

module TurboStreamActions
  extend ActiveSupport::Concern

  def update_flash_stream(notice: nil, alert: nil)
    turbo_stream.update("flash_messages",
      partial: "shared/flash_messages",
      locals: { notice:, alert: }
    )
  end

  def update_milestone_data_streams(project, data)
    streams = []
    
    if data[:time_logs_completed]
      streams << turbo_stream.update("completed_tasks_section",
        partial: "time_logs/completed_tasks_section",
        locals: {
          time_logs_completed: data[:time_logs_completed],
          project: project,
          owner: data[:owner]
        }
      )
    end

    if data[:milestones_pending_confirmation]
      streams << turbo_stream.update("pending_confirmation_section",
        partial: "time_logs/pending_confirmation_section",
        locals: {
          milestones_pending_confirmation: data[:milestones_pending_confirmation],
          project: project,
          owner: data[:owner]
        }
      )
    end

    streams
  end
end
