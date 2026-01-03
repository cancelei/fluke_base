# frozen_string_literal: true

class CreateEnvironmentConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :environment_configs do |t|
      t.references :project, null: false, foreign_key: true
      t.string :environment, null: false
      t.text :description
      t.datetime :last_synced_at
      t.integer :sync_count, default: 0
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :environment_configs, [:project_id, :environment], unique: true
  end
end
