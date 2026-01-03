# frozen_string_literal: true

class CreateMcpPresets < ActiveRecord::Migration[8.0]
  def change
    create_table :mcp_presets do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :target_role, null: false  # founder, developer, contractor
      t.jsonb :enabled_plugins, default: []
      t.jsonb :token_scopes, default: []
      t.jsonb :context_level, default: {}  # minimal, standard, full config
      t.boolean :system_preset, default: false

      t.timestamps
    end

    add_index :mcp_presets, :slug, unique: true
    add_index :mcp_presets, :target_role
    add_index :mcp_presets, :system_preset
  end
end
