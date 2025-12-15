class AddInstagramToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :instagram, :string
  end
end
