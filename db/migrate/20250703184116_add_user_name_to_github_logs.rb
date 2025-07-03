class AddUserNameToGithubLogs < ActiveRecord::Migration[8.0]
  def change
    remove_index :github_logs, name: "index_for_unique_logs"
    add_index :github_logs, [ :project_id, :commit_sha, :agreement_id ], unique: true, name: "index_github_logs_on_project_id_and_commit_sha_and_agreement_id"
    add_column :github_logs, :unregistered_user_name, :string
  end
end
