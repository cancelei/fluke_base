# frozen_string_literal: true

module FlukebaseConnect
  # Service for generating optimized project context for AI agents.
  # Respects context options from project MCP configuration to minimize token usage.
  class MinimalContextService
    CHARS_PER_TOKEN_ESTIMATE = 4

    def initialize(project, user, context_options = {})
      @project = project
      @user = user
      @options = (context_options || {}).with_indifferent_access
    end

    def generate
      context = { project: minimal_project_info }

      context[:milestones] = milestones_info if include?(:milestones)
      context[:team] = team_info if include?(:team)
      context[:environment] = environment_info if include?(:environment)
      context[:conventions] = conventions_info if include?(:conventions)
      context[:agreements] = agreements_info if include?(:agreements)
      context[:gotchas] = gotchas_info if include?(:gotchas)

      # Token optimization: estimate and truncate if needed
      optimize_for_tokens(context)
    end

    private

    def include?(key)
      @options.fetch("include_#{key}", false)
    end

    def max_tokens
      @options.fetch(:max_context_tokens, 2000)
    end

    def minimal_project_info
      {
        id: @project.id,
        name: @project.name,
        repository_url: @project.repository_url,
        stage: @project.stage,
        description: truncate_text(@project.description, 200)
      }.compact
    end

    def milestones_info
      return [] unless @project.respond_to?(:milestones)

      @project.milestones
        .order(created_at: :desc)
        .limit(5)
        .map do |m|
          {
            title: m.title,
            status: m.status,
            due_date: m.due_date&.iso8601
          }.compact
        end
    end

    def team_info
      # Only return essential team info to minimize token usage
      team = [{ role: "owner", name: @project.user.full_name }]

      if @project.respond_to?(:project_memberships)
        @project.project_memberships.accepted.limit(5).each do |membership|
          team << {
            role: membership.role,
            name: membership.user.full_name
          }
        end
      end

      team.uniq { |m| m[:name] }
    end

    def environment_info
      return {} unless @project.respond_to?(:environment_variables)

      environments = EnvironmentVariable::ENVIRONMENTS.select do |env|
        @project.has_environment?(env)
      end

      {
        configured_environments: environments,
        variable_count: @project.environment_variables.count
      }
    end

    def conventions_info
      # Placeholder for project conventions
      # Could be extended to pull from memory store or project settings
      []
    end

    def agreements_info
      return {} unless @project.respond_to?(:agreements)

      {
        active_count: @project.agreements.where(status: "Accepted").count,
        pending_count: @project.agreements.where(status: "Pending").count
      }
    end

    def gotchas_info
      # Placeholder for project-specific gotchas
      # Could be extended to pull from memory store
      []
    end

    def truncate_text(text, max_length)
      return nil if text.blank?
      return text if text.length <= max_length

      text[0, max_length - 3] + "..."
    end

    def estimate_tokens(content)
      content.to_json.length / CHARS_PER_TOKEN_ESTIMATE
    end

    def optimize_for_tokens(context)
      estimated = estimate_tokens(context)

      return context if estimated <= max_tokens

      # Progressively remove optional sections to fit within token limit
      removable_keys = [:gotchas, :conventions, :agreements, :milestones, :team]

      removable_keys.each do |key|
        context.delete(key)
        break if estimate_tokens(context) <= max_tokens
      end

      # If still over limit, truncate the description further
      if estimate_tokens(context) > max_tokens && context[:project][:description]
        context[:project][:description] = truncate_text(
          context[:project][:description],
          50
        )
      end

      context
    end
  end
end
