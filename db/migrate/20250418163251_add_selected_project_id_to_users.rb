class AddSelectedProjectIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :selected_project_id, :integer
  end
end
