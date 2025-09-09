class AddUserProjectReferences < ActiveRecord::Migration[8.0]
  def change
    # Add the selected_project reference to users table now that projects exist
    add_reference :users, :selected_project, foreign_key: { to_table: :projects, on_delete: :nullify }
    add_index :users, :selected_project_id
  end
end
