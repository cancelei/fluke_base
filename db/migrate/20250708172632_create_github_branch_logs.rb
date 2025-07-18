class CreateGithubBranchLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :github_branch_logs do |t|
      t.references :github_branch, null: false
      t.references :github_log, null: false
      t.timestamps
    end

    add_index :github_branch_logs, [ :github_branch_id, :github_log_id ], unique: true
  end
end
