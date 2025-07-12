class ProjectInTimeLogs < ActiveRecord::Migration[8.0]
  def up
    remove_index :time_logs, name: "index_time_logs_on_agreement_id_and_milestone_id"
    remove_index :time_logs, name: "index_time_logs_on_milestone_id"
    remove_reference :time_logs, :agreement, foreign_key: true, index: true

    add_reference :time_logs, :project, foreign_key: true, index: false
    add_index :time_logs, [ :project_id, :milestone_id ], name: "index_time_logs_on_project_id_and_milestone_id"
  end

  def down
    remove_index :time_logs, name: "index_time_logs_on_project_id_and_milestone_id"
    remove_reference :time_logs, :project, foreign_key: true, index: false

    add_reference :time_logs, :agreement, foreign_key: true, index: true
    add_index :time_logs, [ :agreement_id, :milestone_id ], name: "index_time_logs_on_agreement_id_and_milestone_id"
    add_index :time_logs, :milestone_id, name: "index_time_logs_on_milestone_id"
  end
end
