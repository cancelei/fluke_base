class RemoveUniqueFromGithubLogs < ActiveRecord::Migration[8.0]
  def up
    remove_index :github_logs, [ :project_id, :commit_sha, :github_branches_id ], unique: true
    remove_column :github_logs, :github_branches_id
  end

  def down
    add_column :github_logs, :github_branches_id, :bigint
    add_index :github_logs, [ :project_id, :commit_sha, :github_branches_id ], unique: true, name: 'index_github_logs_on_project_commit_branch'
  end
end
