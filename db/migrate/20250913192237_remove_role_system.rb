class RemoveRoleSystem < ActiveRecord::Migration[8.0]
  def change
    # Remove foreign key from users table first
    remove_foreign_key :users, :roles, column: :current_role_id if foreign_key_exists?(:users, :roles, column: :current_role_id)

    # Remove current_role_id column from users
    remove_column :users, :current_role_id, :bigint if column_exists?(:users, :current_role_id)

    # Drop user_roles table (this will automatically drop its foreign keys)
    drop_table :user_roles, if_exists: true

    # Drop roles table
    drop_table :roles, if_exists: true
  end
end
