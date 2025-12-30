# frozen_string_literal: true

# == Schema Information
#
# Table name: mcp_presets
#
#  id              :bigint           not null, primary key
#  context_level   :jsonb
#  token_scopes    :jsonb
#  description     :text
#  enabled_plugins :jsonb
#  name            :string           not null
#  slug            :string           not null
#  system_preset   :boolean          default(FALSE)
#  target_role     :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_mcp_presets_on_slug           (slug) UNIQUE
#  index_mcp_presets_on_system_preset  (system_preset)
#  index_mcp_presets_on_target_role    (target_role)
#
class McpPreset < ApplicationRecord
  # Target roles
  TARGET_ROLES = %w[founder developer contractor].freeze

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :target_role, presence: true, inclusion: { in: TARGET_ROLES }

  # Scopes
  scope :system_presets, -> { where(system_preset: true) }
  scope :for_role, ->(role) { where(target_role: role) }

  # System preset definitions
  SYSTEM_PRESETS = [
    {
      name: "Founder Quick Start",
      slug: "founder",
      description: "Essential tools for project owners. Minimal setup, maximum productivity. Optimized for low context window usage.",
      target_role: "founder",
      enabled_plugins: ["flukebase-core", "environment"],
      token_scopes: ["read:projects", "read:environment", "read:context"],
      context_level: {
        include_milestones: false,
        include_agreements: false,
        include_team: false,
        include_environment: true,
        max_context_tokens: 500
      }
    },
    {
      name: "Developer Full",
      slug: "developer",
      description: "Complete toolkit for active development. All tools enabled with full project context.",
      target_role: "developer",
      enabled_plugins: ["flukebase-core", "environment", "memory"],
      token_scopes: ApiToken::DEFAULT_SCOPES,
      context_level: {
        include_milestones: true,
        include_agreements: true,
        include_team: true,
        include_environment: true,
        include_conventions: true,
        max_context_tokens: 5000
      }
    },
    {
      name: "Contractor Limited",
      slug: "contractor",
      description: "Scoped access for contractors. Read-only with specific project context. Safe for handover.",
      target_role: "contractor",
      enabled_plugins: ["flukebase-core", "environment"],
      token_scopes: ["read:projects", "read:environment"],
      context_level: {
        include_milestones: true,
        include_agreements: false,
        include_team: true,
        include_environment: true,
        max_context_tokens: 2000
      }
    }
  ].freeze

  # Seed system presets
  def self.seed_system_presets!
    SYSTEM_PRESETS.each do |preset_data|
      find_or_create_by!(slug: preset_data[:slug]) do |preset|
        preset.assign_attributes(preset_data.merge(system_preset: true))
      end
    end
  end

  # Get icon for the target role
  def role_icon
    case target_role
    when "founder" then "building-office-2"
    when "developer" then "code-bracket"
    when "contractor" then "briefcase"
    else "user"
    end
  end

  # Get badge color for the role
  def role_badge_variant
    case target_role
    when "founder" then :primary
    when "developer" then :success
    when "contractor" then :warning
    else :neutral
    end
  end
end
