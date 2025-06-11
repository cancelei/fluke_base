class CreateGithubLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :github_logs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :agreement, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :commit_sha
      t.text :commit_message
      t.integer :lines_added
      t.integer :lines_removed
      t.datetime :commit_date

      t.timestamps
    end
  end
end
