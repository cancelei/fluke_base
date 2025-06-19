class RemoveNotNullConstraintFromMilestoneIdInTimeLogs < ActiveRecord::Migration[8.0]
  def change
    change_column_null :time_logs, :milestone_id, true
  end
end
