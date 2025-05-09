class AddPublicFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :public_fields, :string, array: true, default: [], null: false
  end
end
