# frozen_string_literal: true

module Github
  # Handles Turbo Stream broadcasts for GitHub updates
  #
  # Extracts broadcasting logic from:
  # - GithubCommitRefreshJob#broadcast_github_updates
  # - GithubFetchBranchesJob#broadcast_* methods
  #
  # Usage:
  #   broadcaster = Github::BroadcastService.new(project)
  #   broadcaster.broadcast_updates
  #   broadcaster.broadcast_loading_state
  #   broadcaster.broadcast_empty_state
  #
  class BroadcastService
    include ActionView::RecordIdentifier

    attr_reader :project

    STREAM_CHANNEL = "project_%{id}_github_commits"

    # Initialize the broadcaster
    # @param project [Project] The project to broadcast updates for
    def initialize(project)
      @project = project
    end

    # Broadcast all GitHub section updates
    def broadcast_updates
      broadcast_stats
      broadcast_contributions
      broadcast_commits
      broadcast_filters
    end

    # Broadcast stats section update
    def broadcast_stats
      stats = StatisticsCalculator.new(project:)

      broadcast_replace("github_stats", "github_logs/stats_section", {
        total_commits: stats.total_commits,
        total_additions: stats.total_additions,
        total_deletions: stats.total_deletions,
        last_updated: stats.last_updated,
        project:
      })
    end

    # Broadcast contributions section update
    def broadcast_contributions
      contributions = ContributionsSummary.new(project:).call
      stats = StatisticsCalculator.new(project:)

      broadcast_replace("contributions_summary", "github_logs/contributions_section", {
        contributions:,
        last_updated: stats.last_updated,
        project:
      })
    end

    # Broadcast commits list update
    def broadcast_commits
      recent_commits = project.github_logs
        .includes(:user, :github_branch_logs)
        .order(commit_date: :desc)
        .limit(15)

      broadcast_replace("github_logs", "github_logs/commits_list", {
        recent_commits:,
        project:
      })
    end

    # Broadcast filters section update (branches and users dropdowns)
    def broadcast_filters
      # Get available branches and users using the same logic as the controller
      logs_query = Github::LogsQuery.new(project:, params: {})
      available_branches = logs_query.available_branches
      available_users = logs_query.available_users

      broadcast_update("github_filters", "github_logs/filters_section", {
        available_branches:,
        available_users:,
        project:,
        selected_branch: nil,
        agreement_only: false,
        user_name: nil
      })
    end

    # Broadcast loading state
    def broadcast_loading_state
      broadcast_replace("github_logs", "github_logs/loading_state", {})
    end

    # Broadcast empty state
    def broadcast_empty_state
      broadcast_replace("github_logs", "github_logs/empty_state", {
        project:
      })
    end

    # Broadcast reload success notification
    def broadcast_reload_notification
      Turbo::StreamsChannel.broadcast_append_to(
        stream_name,
        target: "github_logs",
        partial: "github_logs/github_commits_reload"
      )
    end

    private

    def stream_name
      STREAM_CHANNEL % { id: project.id }
    end

    def broadcast_replace(target, partial, locals)
      Turbo::StreamsChannel.broadcast_replace_to(
        stream_name,
        target:,
        partial:,
        locals:
      )
    end

    def broadcast_update(target, partial, locals)
      Turbo::StreamsChannel.broadcast_update_to(
        stream_name,
        target:,
        partial:,
        locals:
      )
    end
  end
end
