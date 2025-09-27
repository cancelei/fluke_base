class MakeUserIdOptionalInGithubLogs < ActiveRecord::Migration[8.0]
  def change
    change_column_null :github_logs, :user_id, true
  end
end
