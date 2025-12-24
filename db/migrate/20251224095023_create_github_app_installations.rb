class CreateGithubAppInstallations < ActiveRecord::Migration[8.0]
  def change
    create_table :github_app_installations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :installation_id, null: false
      t.string :account_login
      t.string :account_type
      t.jsonb :repository_selection, default: {}
      t.jsonb :permissions, default: {}
      t.datetime :installed_at

      t.timestamps
    end

    add_index :github_app_installations, :installation_id, unique: true
  end
end
