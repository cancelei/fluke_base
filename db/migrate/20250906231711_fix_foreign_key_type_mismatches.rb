class FixForeignKeyTypeMismatches < ActiveRecord::Migration[8.0]
  def up
    # First, remove the existing foreign key constraint
    remove_foreign_key :users, column: :selected_project_id if foreign_key_exists?(:users, :projects)

    # Change the column type from integer to bigint to match projects.id
    change_column :users, :selected_project_id, :bigint

    # Re-add the foreign key constraint
    add_foreign_key :users, :projects, column: :selected_project_id, on_delete: :nullify
  end

  def down
    # Remove the foreign key constraint
    remove_foreign_key :users, column: :selected_project_id if foreign_key_exists?(:users, :projects)

    # Change the column type back to integer
    change_column :users, :selected_project_id, :integer

    # Re-add the foreign key constraint
    add_foreign_key :users, :projects, column: :selected_project_id, on_delete: :nullify
  end

  private

  def foreign_key_exists?(from_table, to_table)
    foreign_keys = connection.foreign_keys(from_table)
    foreign_keys.any? { |fk| fk.to_table.to_s == to_table.to_s }
  end
end
