class AddOnboardedToUserRoles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_roles, :onboarded, :boolean, default: false
  end
end
