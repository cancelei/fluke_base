# frozen_string_literal: true

class CreateEnvironmentVariables < ActiveRecord::Migration[8.0]
  def change
    create_table :environment_variables do |t|
      t.references :project, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.string :key, null: false
      t.text :value_ciphertext
      t.text :description
      t.string :environment, null: false, default: "development"
      t.boolean :is_secret, null: false, default: false
      t.boolean :is_required, null: false, default: false
      t.string :validation_regex
      t.text :example_value

      t.timestamps
    end

    add_index :environment_variables, [:project_id, :environment, :key],
              unique: true,
              name: "idx_env_vars_project_env_key"
    add_index :environment_variables, [:project_id, :environment]
  end
end
