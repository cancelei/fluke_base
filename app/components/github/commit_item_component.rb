# frozen_string_literal: true

module Github
  # Displays a single commit item with details and diff
  #
  # Extracted from app/views/github_logs/_commit_item.html.erb (117 lines)
  #
  # Usage:
  #   <%= render Github::CommitItemComponent.new(
  #     commit: github_log,
  #     project: project,
  #     associated_time_log: time_log
  #   ) %>
  #
  class CommitItemComponent < ApplicationComponent
    DEFAULT_AVATAR = "https://w7.pngwing.com/pngs/205/731/png-transparent-default-avatar-thumbnail.png"

    # Initialize the component
    # @param commit [GithubLog] The commit record
    # @param project [Project] The project
    # @param associated_time_log [TimeLog, nil] Optional associated time log
    def initialize(commit:, project:, associated_time_log: nil)
      @commit = commit
      @project = project
      @associated_time_log = associated_time_log
    end

    # User who made the commit
    # @return [User, nil]
    def user
      @commit.user
    end

    # Whether the commit author is the project owner
    # @return [Boolean]
    def owner?
      user == @project.user
    end

    # User's avatar URL with fallback
    # @return [String]
    def avatar_url
      user&.avatar_url.presence || DEFAULT_AVATAR
    end

    # User's name or unregistered name
    # @return [String]
    def author_name
      if user
        user.full_name
      else
        "#{@commit.unregistered_user_name} (Unknown User)"
      end
    end

    # Short SHA for display
    # @return [String]
    def short_sha
      @commit.commit_sha[0..6]
    end

    # Formatted commit date
    # @return [String]
    def formatted_date
      @commit.commit_date.strftime("%b %d, %Y %I:%M%p")
    end

    # First line of commit message
    # @return [String]
    def first_line
      @commit.commit_message.split("\n").first
    end

    # Whether commit has extended message
    # @return [Boolean]
    def has_extended_message?
      @commit.commit_message.include?("\n")
    end

    # Extended commit message (everything after first line)
    # @return [String]
    def extended_message
      @commit.commit_message.split("\n")[1..-1].join("\n")
    end

    # Whether there are changed files to display
    # @return [Boolean]
    def has_changed_files?
      @commit.changed_files.present?
    end

    # Changed files data
    # @return [Array<Hash>]
    def changed_files
      @commit.changed_files || []
    end

    # Whether this commit has an associated time log
    # @return [Boolean]
    def has_time_log?
      @associated_time_log.present?
    end

    # CSS class for file status badge
    # @param status [String]
    # @return [String]
    def file_status_class(status)
      case status
      when "added" then "badge-success"
      when "removed" then "badge-error"
      else "badge-info"
      end
    end

    private

    attr_reader :commit, :project, :associated_time_log
  end
end
