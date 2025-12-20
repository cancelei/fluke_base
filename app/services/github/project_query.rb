# frozen_string_literal: true

module Github
  # Query service for GitHub data on a project
  #
  # Provides read-only queries for project GitHub data.
  # Renamed from ProjectGithubService for better namespace organization.
  #
  # Usage:
  #   query = Github::ProjectQuery.new(project)
  #   query.connected?           # => true
  #   query.available_branches   # => [[1, "main"], [2, "develop"]]
  #   query.can_view_logs?(user) # => true
  #
  class ProjectQuery
    attr_reader :project

    # Initialize the query service
    # @param project [Project] The project to query
    def initialize(project)
      @project = project
    end

    # Check if the project has a repository configured
    # @return [Boolean]
    def connected?
      project.repository_url.present?
    end

    # Get available branches for the project
    # @return [Array<Array>] Array of [id, branch_name] pairs
    def available_branches
      project.github_branches.pluck(:id, :branch_name).compact.sort_by { |_, name| name.to_s }
    end

    # Get recent commit logs
    # @param limit [Integer] Maximum number of logs to return
    # @return [ActiveRecord::Relation]
    def recent_logs(limit = 20)
      project.github_logs.includes(:user).order(commit_date: :desc).limit(limit)
    end

    # Get contributions summary (delegates to ContributionsSummary)
    # @param branch [String, nil] Optional branch filter
    # @return [Array<Hash>] Contribution data
    def contributions_summary(branch = nil)
      ContributionsSummary.new(project:, branch:).call
    end

    # Alias for backward compatibility with ProjectGithubService
    def contributions_summary_basic
      project.github_contributions
    end

    # Check if a user can view GitHub logs
    # @param user [User] The user to check
    # @return [Boolean]
    def can_view_logs?(user)
      return false unless user

      # Project owner can always view logs
      return true if project.user == user

      # Users with active agreements can view logs
      project.agreements.active.joins(:agreement_participants)
             .exists?(agreement_participants: { user_id: user.id })
    end

    # Check if a user can access the repository
    # @param user [User] The user to check
    # @return [Boolean]
    def can_access_repository?(user)
      can_view_logs?(user)
    end

    # Get GitHub activity statistics
    # @return [Hash]
    def activity_stats
      StatisticsCalculator.new(project:).to_h
    end
  end
end
