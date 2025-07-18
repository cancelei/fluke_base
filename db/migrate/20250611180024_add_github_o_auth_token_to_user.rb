class AddGithubOAuthTokenToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :github_token, :string
  end
end
