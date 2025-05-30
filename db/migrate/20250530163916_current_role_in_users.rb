class CurrentRoleInUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :current_role, foreign_key: { to_table: :roles }
  end
end
