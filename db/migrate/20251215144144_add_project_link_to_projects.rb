class AddProjectLinkToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :project_link, :string unless column_exists?(:projects, :project_link)
  end
end
