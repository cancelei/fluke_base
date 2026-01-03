# frozen_string_literal: true

# == Schema Information
#
# Table name: project_mcp_configurations
#
#  id              :bigint           not null, primary key
#  context_options :jsonb
#  enabled_plugins :jsonb
#  plugin_settings :jsonb
#  preset          :string           default("developer")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  project_id      :bigint           not null
#
# Indexes
#
#  index_project_mcp_configurations_on_project_id  (project_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
class ProjectMcpConfiguration < ApplicationRecord
  belongs_to :project

  # Available presets
  PRESETS = %w[founder developer contractor custom].freeze

  # Context level configurations
  CONTEXT_LEVELS = {
    minimal: {
      include_milestones: false,
      include_agreements: false,
      include_team: false,
      include_environment: true,
      include_conventions: false,
      max_context_tokens: 500
    },
    standard: {
      include_milestones: true,
      include_agreements: false,
      include_team: true,
      include_environment: true,
      include_conventions: false,
      max_context_tokens: 2000
    },
    full: {
      include_milestones: true,
      include_agreements: true,
      include_team: true,
      include_environment: true,
      include_conventions: true,
      include_gotchas: true,
      max_context_tokens: 5000
    }
  }.freeze

  # Validations
  validates :preset, inclusion: { in: PRESETS }

  # Get enabled plugin records
  def effective_plugins
    return McpPlugin.none if enabled_plugins.blank?

    McpPlugin.active.where(slug: enabled_plugins)
  end

  # Get the context level configuration
  def context_level
    return CONTEXT_LEVELS[:standard] if context_options.blank?

    CONTEXT_LEVELS[:standard].merge(context_options.symbolize_keys)
  end

  # Apply a preset to this configuration
  def apply_preset!(preset_slug)
    preset = McpPreset.find_by(slug: preset_slug)
    return false unless preset

    update!(
      preset: preset_slug,
      enabled_plugins: preset.enabled_plugins,
      context_options: preset.context_level
    )
    true
  end

  # Check if a specific plugin is enabled
  def plugin_enabled?(plugin_slug)
    enabled_plugins.include?(plugin_slug)
  end

  # Enable a plugin
  def enable_plugin!(plugin_slug)
    return if plugin_enabled?(plugin_slug)

    self.enabled_plugins = (enabled_plugins || []) + [plugin_slug]
    self.preset = "custom"
    save!
  end

  # Disable a plugin
  def disable_plugin!(plugin_slug)
    return unless plugin_enabled?(plugin_slug)

    self.enabled_plugins = enabled_plugins - [plugin_slug]
    self.preset = "custom"
    save!
  end

  # Get setting for a specific plugin
  def setting_for(plugin_slug)
    (plugin_settings || {})[plugin_slug] || {}
  end
end
