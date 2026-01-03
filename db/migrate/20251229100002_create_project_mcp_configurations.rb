# frozen_string_literal: true

class CreateProjectMcpConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :project_mcp_configurations do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.string :preset, default: "developer"  # founder, developer, contractor, custom
      t.jsonb :enabled_plugins, default: []   # Array of plugin slugs
      t.jsonb :plugin_settings, default: {}   # Per-plugin configuration
      t.jsonb :context_options, default: {}   # What context to send to AI

      t.timestamps
    end
  end
end
