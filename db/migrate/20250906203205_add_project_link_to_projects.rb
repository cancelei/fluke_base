class AddProjectLinkToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :project_link, :string, default: nil
  end
end
