class NewUserFields < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :years_of_experience, :float
    add_column :users, :hourly_rate, :float
    add_column :users, :industries, :string, array: true, default: []
    add_column :users, :skills, :string, array: true, default: []
    add_column :users, :business_stage, :string
    add_column :users, :help_seekings, :string, array: true, default: []
    add_column :users, :business_info, :text
  end
end
