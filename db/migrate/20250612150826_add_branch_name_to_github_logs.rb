class AddBranchNameToGithubLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :github_logs, :branch_name, :string
  end
end
