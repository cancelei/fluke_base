class AddGithubLastPolledAtToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :github_last_polled_at, :datetime
    add_index :projects, :github_last_polled_at
  end
end
