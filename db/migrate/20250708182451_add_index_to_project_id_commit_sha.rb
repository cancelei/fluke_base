class AddIndexToProjectIdCommitSha < ActiveRecord::Migration[8.0]
  def change
    add_index :github_logs, [ :project_id, :commit_sha ], unique: true, name: 'index_github_logs_on_project_commit_sha'
  end
end
