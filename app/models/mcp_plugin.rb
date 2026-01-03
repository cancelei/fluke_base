# frozen_string_literal: true

# == Schema Information
#
# Table name: mcp_plugins
#
#  id                   :bigint           not null, primary key
#  active               :boolean          default(TRUE)
#  author               :string
#  built_in             :boolean          default(FALSE)
#  configuration_schema :jsonb
#  description          :text
#  features             :jsonb
#  homepage             :string
#  icon_name            :string
#  maturity             :string           not null
#  name                 :string           not null
#  plugin_type          :string           not null
#  required_scopes      :string           default([]), is an Array
#  slug                 :string           not null
#  version              :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_mcp_plugins_on_active       (active)
#  index_mcp_plugins_on_maturity     (maturity)
#  index_mcp_plugins_on_plugin_type  (plugin_type)
#  index_mcp_plugins_on_slug         (slug) UNIQUE
#
class McpPlugin < ApplicationRecord
  # Enums
  enum :plugin_type, {
    ai_provider: "ai_provider",
    integration: "integration",
    tool: "tool"
  }, prefix: true

  enum :maturity, {
    conceptual: "conceptual",
    mvp: "mvp",
    production: "production"
  }, prefix: true

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :version, presence: true
  validates :plugin_type, presence: true
  validates :maturity, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :built_in, -> { where(built_in: true) }
  scope :by_type, ->(type) { where(plugin_type: type) }
  scope :production_ready, -> { maturity_production }

  # Default maturity features for each level
  MATURITY_FEATURES = {
    conceptual: {
      documentation: false,
      basic_functionality: false,
      error_handling: false,
      tests: false,
      performance_optimized: false
    },
    mvp: {
      documentation: true,
      basic_functionality: true,
      error_handling: true,
      tests: false,
      performance_optimized: false
    },
    production: {
      documentation: true,
      basic_functionality: true,
      error_handling: true,
      tests: true,
      performance_optimized: true
    }
  }.freeze

  # Get the combined maturity features (defaults + custom)
  def maturity_features
    defaults = MATURITY_FEATURES[maturity.to_sym] || {}
    defaults.merge((features || {}).symbolize_keys)
  end

  # Check if a specific feature is complete
  def feature_complete?(feature)
    maturity_features[feature.to_sym] == true
  end

  # Get the maturity badge variant for UI
  def maturity_badge_variant
    case maturity
    when "production" then :success
    when "mvp" then :warning
    when "conceptual" then :neutral
    else :neutral
    end
  end

  # Get the plugin type icon for UI
  def type_icon
    case plugin_type
    when "ai_provider" then "cpu-chip"
    when "integration" then "puzzle-piece"
    when "tool" then "wrench-screwdriver"
    else "cube"
    end
  end
end
