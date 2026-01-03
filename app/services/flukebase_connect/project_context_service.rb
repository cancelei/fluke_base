# frozen_string_literal: true

module FlukebaseConnect
  # Generates AI-optimized project context for flukebase_connect
  # This context helps Claude Code understand the project structure,
  # team, milestones, and conventions.
  class ProjectContextService
    def initialize(project, user)
      @project = project
      @user = user
    end

    def generate
      {
        project: project_info,
        milestones: milestones_info,
        agreements: agreements_info,
        team: team_info,
        environment: environment_info,
        conventions: conventions_info,
        gotchas: gotchas_info,
        mcp_configuration: mcp_configuration_info
      }
    end

    private

    def project_info
      {
        id: @project.id,
        name: @project.name,
        description: @project.description,
        repository_url: @project.repository_url,
        stage: @project.stage,
        collaboration_type: @project.collaboration_type,
        created_at: @project.created_at.iso8601,
        updated_at: @project.updated_at.iso8601,
        framework: detect_framework
      }
    end

    def milestones_info
      @project.milestones.order(:created_at).map do |m|
        {
          id: m.id,
          title: m.title,
          description: m.description,
          status: m.status,
          due_date: m.due_date&.iso8601
        }
      end
    end

    def agreements_info
      active_statuses = %w[Accepted Completed]
      @project.agreements
              .where(status: active_statuses)
              .includes(:agreement_participants)
              .map do |a|
        {
          id: a.id,
          type: a.agreement_type,
          status: a.status,
          participants: agreement_participants(a)
        }
      end
    end

    def agreement_participants(agreement)
      agreement.agreement_participants.includes(:user).map do |ap|
        {
          name: ap.user.full_name,
          role: ap.user_role,
          is_initiator: ap.is_initiator
        }
      end
    end

    def team_info
      # Collect all team members from various sources
      team_members = Set.new

      # Project owner
      team_members << {
        id: @project.user.id,
        name: @project.user.full_name,
        role: "owner"
      }

      # Agreement participants
      active_statuses = %w[Accepted Completed]
      @project.agreements
              .where(status: active_statuses)
              .includes(agreement_participants: :user)
              .flat_map(&:agreement_participants)
              .each do |ap|
        team_members << {
          id: ap.user.id,
          name: ap.user.full_name,
          role: ap.user_role || "collaborator"
        }
      end

      # Project memberships
      @project.project_memberships.includes(:user).each do |pm|
        team_members << {
          id: pm.user.id,
          name: pm.user.full_name,
          role: pm.role
        }
      end

      # Convert to array and dedupe by id
      team_members.uniq { |m| m[:id] }.to_a
    end

    def environment_info
      {
        has_development: @project.has_environment?("development"),
        has_staging: @project.has_environment?("staging"),
        has_production: @project.has_environment?("production"),
        total_variables: @project.environment_variables.count
      }
    end

    def conventions_info
      # Load conventions from project_memories
      db_conventions = @project.project_memories.conventions.map do |c|
        {
          key: c.key,
          value: c.content,
          rationale: c.rationale,
          tags: c.tags
        }
      end

      # Fall back to defaults if no conventions stored
      if db_conventions.empty?
        default_conventions
      else
        db_conventions
      end
    end

    def gotchas_info
      # Load gotchas from project_memories
      @project.project_memories.gotchas.map do |g|
        {
          id: g.id,
          content: g.content,
          tags: g.tags,
          references: g.references
        }
      end
    end

    def default_conventions
      # Return standard Rails/Ruby conventions as fallback
      [
        {
          key: "testing",
          value: "RSpec with FactoryBot",
          rationale: "Standard Ruby testing stack",
          tags: []
        },
        {
          key: "linting",
          value: "RuboCop",
          rationale: "Ruby style enforcement",
          tags: []
        }
      ]
    end

    def detect_framework
      # Try to detect from repository or stored metadata
      # Could be enhanced with actual repo analysis
      repo_url = @project.repository_url
      return nil unless repo_url.present?

      # Check for common patterns in repo name
      if repo_url.include?("rails") || repo_url.include?("_api")
        "rails"
      elsif repo_url.include?("django")
        "django"
      elsif repo_url.include?("next") || repo_url.include?("react")
        "react"
      else
        nil
      end
    end

    def mcp_configuration_info
      config = @project.mcp_configuration
      return default_mcp_configuration unless config

      {
        preset: config.preset,
        enabled_plugins: config.enabled_plugins || [],
        context_options: config.context_level,
        plugin_settings: config.plugin_settings || {},
        plugins: enabled_plugins_info(config)
      }
    end

    def enabled_plugins_info(config)
      config.effective_plugins.map do |plugin|
        {
          slug: plugin.slug,
          name: plugin.name,
          description: plugin.description,
          plugin_type: plugin.plugin_type,
          maturity: plugin.maturity,
          required_scopes: plugin.required_scopes,
          configuration_schema: plugin.configuration_schema
        }
      end
    end

    def default_mcp_configuration
      # Default to developer preset if no configuration exists
      preset = McpPreset.find_by(slug: "developer")
      {
        preset: "developer",
        enabled_plugins: preset&.enabled_plugins || ["flukebase-core", "environment", "memory"],
        context_options: preset&.context_level || ProjectMcpConfiguration::CONTEXT_LEVELS[:standard],
        plugin_settings: {},
        plugins: default_plugins_info
      }
    end

    def default_plugins_info
      McpPlugin.active.built_in.map do |plugin|
        {
          slug: plugin.slug,
          name: plugin.name,
          description: plugin.description,
          plugin_type: plugin.plugin_type,
          maturity: plugin.maturity,
          required_scopes: plugin.required_scopes,
          configuration_schema: plugin.configuration_schema
        }
      end
    end
  end
end
