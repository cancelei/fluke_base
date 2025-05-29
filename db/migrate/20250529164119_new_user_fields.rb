class NewUserFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :industry, :string
    add_column :users, :years_of_experience, :float
    add_column :users, :hourly_rate, :float
    add_column :users, :industries, :string, array: true, default: []
    add_column :users, :skills, :string, array: true, default: []
  end
end
