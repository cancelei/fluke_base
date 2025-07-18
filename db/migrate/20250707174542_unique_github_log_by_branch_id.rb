class UniqueGithubLogByBranchId < ActiveRecord::Migration[8.0]
  def change
    remove_index :github_logs, name: "index_github_logs_on_project_id_and_commit_sha"
    add_index :github_logs, [ :project_id, :commit_sha, :github_branches_id ], unique: true, name: "index_github_logs_on_project_id_and_commit_sha_and_branch_id"
  end
end
