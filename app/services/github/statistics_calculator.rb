# frozen_string_literal: true

module Github
  # Calculates GitHub statistics for a project
  #
  # Centralizes statistics calculation that was previously duplicated in:
  # - GithubLogsController#index
  # - GithubLogsDataService#stats_data
  # - GithubCommitRefreshJob#broadcast_github_updates
  # - Project#github_activity_stats
  #
  # Usage:
  #   stats = Github::StatisticsCalculator.new(project: project)
  #   stats.total_commits  # => 42
  #   stats.to_h           # => { total_commits: 42, ... }
  #
  #   # With filtered query
  #   query = project.github_logs.where(user_id: 1)
  #   stats = Github::StatisticsCalculator.new(project: project, query: query)
  #
  class StatisticsCalculator
    attr_reader :project, :query

    # Initialize the calculator
    # @param project [Project] The project to calculate stats for
    # @param query [ActiveRecord::Relation, nil] Optional pre-filtered query
    def initialize(project:, query: nil)
      @project = project
      @query = query || project.github_logs
    end

    # Total number of unique commits
    # Uses distinct to avoid double-counting commits in multiple branches
    # @return [Integer]
    def total_commits
      @total_commits ||= query.distinct.count
    end

    # Total lines added across all commits
    # @return [Integer]
    def total_additions
      @total_additions ||= query.distinct.sum(:lines_added).to_i
    end

    # Total lines removed across all commits
    # @return [Integer]
    def total_deletions
      @total_deletions ||= query.distinct.sum(:lines_removed).to_i
    end

    # Net lines changed (additions - deletions)
    # @return [Integer]
    def net_changes
      total_additions - total_deletions
    end

    # Most recent commit date
    # @return [DateTime, Time]
    def last_updated
      @last_updated ||= project.github_logs.maximum(:commit_date) || Time.current
    end

    # Number of unique contributors
    # @return [Integer]
    def contributor_count
      @contributor_count ||= query.distinct.where.not(user_id: nil).select(:user_id).count
    end

    # Number of commits in the last N days
    # @param days [Integer] Number of days to look back
    # @return [Integer]
    def commits_since(days: 7)
      query.where("commit_date > ?", days.days.ago).distinct.count
    end

    # Activity level based on last commit date
    # @return [Symbol] :active, :moderate, :stale, or :none
    def activity_level
      return :none unless project.repository_url.present?

      last_date = project.github_logs.maximum(:commit_date)
      return :stale unless last_date

      days_since_last = (Time.current - last_date).to_i / 1.day

      if days_since_last <= 7
        :active
      elsif days_since_last <= 30
        :moderate
      else
        :stale
      end
    end

    # All statistics as a hash
    # @return [Hash] Statistics hash
    def to_h
      {
        total_commits:,
        total_additions:,
        total_deletions:,
        net_changes:,
        last_updated:,
        contributor_count:,
        commits_this_week: commits_since(days: 7),
        commits_this_month: commits_since(days: 30),
        activity_level:
      }
    end

    # Alias for to_h
    alias_method :call, :to_h
  end
end
