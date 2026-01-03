# frozen_string_literal: true

class CreateMcpPlugins < ActiveRecord::Migration[8.0]
  def change
    create_table :mcp_plugins do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :version, null: false
      t.text :description
      t.string :plugin_type, null: false  # ai_provider, integration, tool
      t.string :maturity, null: false     # conceptual, mvp, production
      t.string :author
      t.string :homepage
      t.string :icon_name                 # Heroicon name for UI
      t.jsonb :features, default: {}      # Maturity feature checklist
      t.jsonb :configuration_schema, default: {}
      t.string :required_scopes, array: true, default: []
      t.boolean :built_in, default: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :mcp_plugins, :slug, unique: true
    add_index :mcp_plugins, :plugin_type
    add_index :mcp_plugins, :maturity
    add_index :mcp_plugins, :active
  end
end
