class AddSlugToMilestones < ActiveRecord::Migration[8.0]
  def change
    add_column :milestones, :slug, :string
    add_index :milestones, [:project_id, :slug], unique: true
  end
end
