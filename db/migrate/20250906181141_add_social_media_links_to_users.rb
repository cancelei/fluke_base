class AddSocialMediaLinksToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :linkedin, :string
    add_column :users, :x, :string
    add_column :users, :youtube, :string
    add_column :users, :facebook, :string
    add_column :users, :tiktok, :string
  end
end
