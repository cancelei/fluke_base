class AddGithubAppToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :github_user_access_token, :string
    add_column :users, :github_refresh_token, :string
    add_column :users, :github_token_expires_at, :datetime
    add_column :users, :github_uid, :string
    add_column :users, :github_connected_at, :datetime

    add_index :users, :github_uid, unique: true
  end
end
