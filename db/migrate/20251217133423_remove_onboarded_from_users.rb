class RemoveOnboardedFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :onboarded, :boolean, default: false
  end
end
