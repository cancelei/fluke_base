# frozen_string_literal: true

# Seed built-in MCP plugins
puts "Seeding MCP Plugins..."

[
  {
    name: "FlukeBase Core",
    slug: "flukebase-core",
    version: "1.0.0",
    description: "Core FlukeBase integration: authentication, projects, and sync",
    plugin_type: "integration",
    maturity: "production",
    author: "FlukeBase",
    homepage: "https://flukebase.com",
    icon_name: "puzzle-piece",
    built_in: true,
    required_scopes: ["read:projects"],
    features: {
      documentation: true,
      basic_functionality: true,
      error_handling: true,
      tests: true,
      offline_mode: false
    }
  },
  {
    name: "Environment Manager",
    slug: "environment",
    version: "1.0.0",
    description: "Sync and manage environment variables across environments",
    plugin_type: "tool",
    maturity: "production",
    author: "FlukeBase",
    homepage: "https://flukebase.com",
    icon_name: "cog-6-tooth",
    built_in: true,
    required_scopes: ["read:environment"],
    features: {
      documentation: true,
      basic_functionality: true,
      error_handling: true,
      tests: true,
      secret_masking: true
    }
  },
  {
    name: "Memory Store",
    slug: "memory",
    version: "1.0.0",
    description: "Persistent memory for AI agents: remember facts, conventions, gotchas",
    plugin_type: "tool",
    maturity: "production",
    author: "FlukeBase",
    homepage: "https://flukebase.com",
    icon_name: "bookmark",
    built_in: true,
    required_scopes: [],
    features: {
      documentation: true,
      basic_functionality: true,
      error_handling: true,
      tests: true,
      scoped_storage: true
    }
  },
  # Conceptual plugins (for future development)
  {
    name: "GitHub Integration",
    slug: "github",
    version: "0.1.0",
    description: "Direct GitHub access: PRs, issues, commits (coming soon)",
    plugin_type: "integration",
    maturity: "conceptual",
    author: "FlukeBase",
    icon_name: "code-bracket-square",
    built_in: false,
    active: false,
    required_scopes: ["read:github"],
    features: {
      documentation: false,
      basic_functionality: false
    }
  },
  {
    name: "OpenAI Provider",
    slug: "openai",
    version: "0.1.0",
    description: "OpenAI API integration for GPT models (coming soon)",
    plugin_type: "ai_provider",
    maturity: "conceptual",
    author: "FlukeBase",
    icon_name: "cpu-chip",
    built_in: false,
    active: false,
    required_scopes: [],
    features: {
      documentation: false,
      basic_functionality: false
    }
  },
  {
    name: "Anthropic Provider",
    slug: "anthropic",
    version: "0.1.0",
    description: "Anthropic Claude API integration (coming soon)",
    plugin_type: "ai_provider",
    maturity: "conceptual",
    author: "FlukeBase",
    icon_name: "cpu-chip",
    built_in: false,
    active: false,
    required_scopes: [],
    features: {
      documentation: false,
      basic_functionality: false
    }
  }
].each do |plugin_data|
  McpPlugin.find_or_create_by!(slug: plugin_data[:slug]) do |plugin|
    plugin.assign_attributes(plugin_data)
  end
end

puts "  Created #{McpPlugin.count} MCP plugins"

# Seed system presets
puts "Seeding MCP Presets..."
McpPreset.seed_system_presets!
puts "  Created #{McpPreset.count} MCP presets"

puts "MCP seeding complete!"
