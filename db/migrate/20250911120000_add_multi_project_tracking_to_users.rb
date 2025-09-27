class AddMultiProjectTrackingToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :multi_project_tracking, :boolean, default: false, null: false unless column_exists?(:users, :multi_project_tracking)
  end
end
