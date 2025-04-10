class AddDetailsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :current_stage, :string
    add_column :projects, :target_market, :text
    add_column :projects, :funding_status, :string
    add_column :projects, :team_size, :string
  end
end
