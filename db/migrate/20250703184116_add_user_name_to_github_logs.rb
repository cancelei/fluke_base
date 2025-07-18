class AddUserNameToGithubLogs < ActiveRecord::Migration[8.0]
  def up
    remove_index :github_logs, name: "index_for_unique_logs"
    add_index :github_logs, [ :project_id, :commit_sha ], unique: true, name: "index_github_logs_on_project_id_and_commit_sha"
    add_column :github_logs, :unregistered_user_name, :string
    change_column_null :github_logs, :agreement_id, true
    change_column_null :github_logs, :user_id, true
  end

  def down
    remove_column :github_logs, :unregistered_user_name, :string
    add_index :github_logs, [ :project_id, :commit_sha, :agreement_id, :user_id ], name: "index_for_unique_logs"
    remove_index :github_logs, name: "index_github_logs_on_project_id_and_commit_sha"
    change_column_null :github_logs, :agreement_id, false
    change_column_null :github_logs, :user_id, false
  end
end
