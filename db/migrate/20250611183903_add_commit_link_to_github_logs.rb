class AddCommitLinkToGithubLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :github_logs, :commit_url, :string
    add_column :github_logs, :changed_files, :jsonb, array: true, default: []
    add_index :github_logs, [ :project_id, :commit_sha, :agreement_id, :user_id ], name: "index_for_unique_logs", unique: true
  end
end
