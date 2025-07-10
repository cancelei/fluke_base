class AddShowProjectContextNavToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :show_project_context_nav, :boolean, default: false, null: false
  end
end
