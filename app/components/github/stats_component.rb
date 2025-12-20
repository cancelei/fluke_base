# frozen_string_literal: true

module Github
  # Displays GitHub statistics (commits, lines added/removed)
  #
  # Extracted from app/views/github_logs/_stats_section.html.erb
  #
  # Usage:
  #   <%= render Github::StatsComponent.new(
  #     total_commits: 42,
  #     total_additions: 1000,
  #     total_deletions: 500
  #   ) %>
  #
  class StatsComponent < ApplicationComponent
    # Initialize the component
    # @param total_commits [Integer] Total number of commits
    # @param total_additions [Integer] Total lines added
    # @param total_deletions [Integer] Total lines removed
    # @param loading [Boolean] Show loading state
    def initialize(total_commits:, total_additions:, total_deletions:, loading: false)
      @total_commits = total_commits.to_i
      @total_additions = total_additions.to_i
      @total_deletions = total_deletions.to_i
      @loading = loading
    end

    # Whether to show loading state
    # @return [Boolean]
    def loading?
      @loading || @total_commits == 0
    end

    # Net lines changed
    # @return [Integer]
    def net_changes
      @total_additions - @total_deletions
    end

    private

    attr_reader :total_commits, :total_additions, :total_deletions
  end
end
