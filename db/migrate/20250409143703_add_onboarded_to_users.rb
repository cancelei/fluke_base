class AddOnboardedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :onboarded, :boolean, default: false
  end
end
