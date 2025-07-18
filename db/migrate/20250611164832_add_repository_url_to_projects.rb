class AddRepositoryUrlToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :repository_url, :string
  end
end
