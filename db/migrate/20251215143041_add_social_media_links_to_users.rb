class AddSocialMediaLinksToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :linkedin, :string unless column_exists?(:users, :linkedin)
    add_column :users, :x, :string unless column_exists?(:users, :x)
    add_column :users, :youtube, :string unless column_exists?(:users, :youtube)
    add_column :users, :facebook, :string unless column_exists?(:users, :facebook)
    add_column :users, :tiktok, :string unless column_exists?(:users, :tiktok)
  end
end
