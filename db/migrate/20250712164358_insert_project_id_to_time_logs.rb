class InsertProjectIdToTimeLogs < ActiveRecord::Migration[8.0]
  def up
    TimeLog.includes(:milestone).find_each do |time_log|
      next if time_log.milestone_id.blank?

      project_id = time_log.milestone.project_id

      next if project_id.blank?

      time_log.update(project_id: project_id)
    end
  end

  def down
    # This migration is not reversible as it sets project_id based on existing data.
    # If you need to revert, you would have to manually set project_id to nil or handle it differently.
  end
end
