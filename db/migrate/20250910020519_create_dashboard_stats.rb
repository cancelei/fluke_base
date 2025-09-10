class CreateDashboardStats < ActiveRecord::Migration[8.0]
  def change
    create_view :dashboard_stats, materialized: true

    # Add index for faster lookups
    add_index :dashboard_stats, :user_id, unique: true
  end
end
