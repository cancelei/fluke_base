class AddStealthModeToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :stealth_mode, :boolean, default: false, null: false
    add_column :projects, :stealth_name, :string
    add_column :projects, :stealth_description, :text
    add_column :projects, :stealth_category, :string

    # Add index for efficient querying of stealth projects
    add_index :projects, :stealth_mode, comment: "Improves filtering of stealth vs public projects"

    # Update existing projects to have stealth_mode = false
    reversible do |dir|
      dir.up do
        execute "UPDATE projects SET stealth_mode = false WHERE stealth_mode IS NULL"
      end
    end
  end
end
