class AddCollaborationTypeToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :collaboration_type, :string
  end
end
