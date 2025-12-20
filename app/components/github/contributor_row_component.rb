# frozen_string_literal: true

module Github
  # Displays a single contributor row in the contributions table
  #
  # Usage:
  #   <%= render Github::ContributorRowComponent.new(
  #     contribution: { user: user, commit_count: 10, ... },
  #     project: project
  #   ) %>
  #
  class ContributorRowComponent < ApplicationComponent
    DEFAULT_AVATAR = "https://w7.pngwing.com/pngs/205/731/png-transparent-default-avatar-thumbnail.png"

    # Initialize the component
    # @param contribution [Hash] Contribution data with :user, :commit_count, etc.
    # @param project [Project] The project for owner badge display
    def initialize(contribution:, project:)
      @contribution = contribution
      @project = project
      @user = contribution[:user]
    end

    # Whether this contributor is the project owner
    # @return [Boolean]
    def owner?
      @user == @project.user
    end

    # Net lines changed
    # @return [Integer]
    def net_changes
      total_added - total_removed
    end

    # CSS class for net changes color
    # @return [String]
    def net_class
      return "text-success" if net_changes.positive?
      return "text-error" if net_changes.negative?
      "text-base-content/60"
    end

    # User's avatar URL with fallback
    # @return [String]
    def avatar_url
      @user.avatar_url.presence || DEFAULT_AVATAR
    end

    # User's full name
    # @return [String]
    def full_name
      @user.full_name
    end

    # GitHub username if available
    # @return [String, nil]
    def github_username
      @user.github_username
    end

    # GitHub profile URL
    # @return [String]
    def github_profile_url
      "https://github.com/#{github_username}"
    end

    # Number of commits
    # @return [Integer]
    def commit_count
      @contribution[:commit_count].to_i
    end

    # Total lines added
    # @return [Integer]
    def total_added
      @contribution[:total_added].to_i
    end

    # Total lines removed
    # @return [Integer]
    def total_removed
      @contribution[:total_removed].to_i
    end

    private

    attr_reader :contribution, :project, :user
  end
end
