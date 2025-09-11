class AddMultiProjectTrackingToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :multi_project_tracking, :boolean, default: false, null: false
  end
end
