class CreateGithubBranches < ActiveRecord::Migration[8.0]
  def up
    create_table :github_branches do |t|
      t.references :project, foreign_key: true
      t.references :user, foreign_key: true
      t.string :branch_name
      t.timestamps
    end
    add_index :github_branches, [ :project_id, :branch_name, :user_id ], unique: true

    remove_column :github_logs, :branch_name, if_exists: true

    add_reference :github_logs, :github_branches, foreign_key: true
  end

  def down
    remove_reference :github_logs, :github_branches
    drop_table :github_branches
  end
end
