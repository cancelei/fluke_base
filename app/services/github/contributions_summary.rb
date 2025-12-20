# frozen_string_literal: true

require "ostruct"

module Github
  # Calculates contributions summary by user
  #
  # Extracts and consolidates logic from:
  # - Project#github_contributions (lines 70-178)
  # - ProjectGithubService#contributions_summary
  #
  # Usage:
  #   summary = Github::ContributionsSummary.new(project: project, branch: "1")
  #   contributions = summary.call
  #   # => [{ user: User, commit_count: 10, total_added: 500, ... }, ...]
  #
  class ContributionsSummary
    attr_reader :project, :branch, :agreement_only, :agreement_user_ids, :user_name

    # Initialize the summary calculator
    # @param project [Project] The project to calculate contributions for
    # @param branch [String, Integer, nil] Optional branch ID to filter by
    # @param agreement_only [Boolean] Filter to agreement participants only
    # @param agreement_user_ids [Array<Integer>, nil] Pre-calculated agreement user IDs
    # @param user_name [String, nil] Filter by unregistered user name
    def initialize(project:, branch: nil, agreement_only: false, agreement_user_ids: nil, user_name: nil)
      @project = project
      @branch = branch
      @agreement_only = agreement_only
      @agreement_user_ids = agreement_user_ids
      @user_name = user_name
    end

    # Calculate contributions and return formatted results
    # @return [Array<Hash>] Array of contribution hashes with :user, :commit_count, etc.
    def call
      return [] unless project.github_logs.exists?

      all_contributions = registered_contributions + unregistered_contributions
      all_contributions.sort_by { |c| -c[:commit_count].to_i }
    end

    private

    def base_query
      query = project.github_logs

      # Apply branch filter
      if branch.present? && branch.to_i != 0
        query = query.joins(:github_branch_logs)
                     .where(github_branch_logs: { github_branch_id: branch })
      end

      # Apply agreement filter
      if agreement_only && agreement_user_ids.present?
        query = query.where(user_id: agreement_user_ids)
      end

      # Apply user_name filter
      if user_name.present?
        query = query.where(unregistered_user_name: user_name)
      end

      query.distinct
    end

    def registered_contributions
      registered_logs = base_query.joins(:user).where.not(users: { id: nil })

      results = registered_logs
        .group(
          "users.id", "users.first_name", "users.last_name",
          "users.email", "users.avatar", "users.github_username"
        )
        .select(
          "users.id as user_id",
          "users.first_name",
          "users.last_name",
          "users.email",
          "users.avatar",
          "users.github_username",
          "COUNT(github_logs.id) as commit_count",
          "SUM(github_logs.lines_added) as total_added",
          "SUM(github_logs.lines_removed) as total_removed",
          "MIN(github_logs.commit_date) as first_commit_date",
          "MAX(github_logs.commit_date) as last_commit_date"
        )

      results.map do |record|
        user = User.find(record.user_id)
        build_contribution_hash(user, record)
      end
    end

    def unregistered_contributions
      unregistered_logs = base_query
        .where(user_id: nil)
        .where.not(unregistered_user_name: [nil, ""])

      results = unregistered_logs
        .group("github_logs.unregistered_user_name")
        .select(
          "github_logs.unregistered_user_name",
          "COUNT(github_logs.id) as commit_count",
          "SUM(github_logs.lines_added) as total_added",
          "SUM(github_logs.lines_removed) as total_removed",
          "MIN(github_logs.commit_date) as first_commit_date",
          "MAX(github_logs.commit_date) as last_commit_date"
        )

      results.map do |record|
        user = build_unregistered_user(record.unregistered_user_name)
        build_contribution_hash(user, record)
      end
    end

    def build_contribution_hash(user, record)
      total_added = record.total_added.to_i
      total_removed = record.total_removed.to_i

      {
        user:,
        commit_count: record.commit_count.to_i,
        total_added:,
        total_removed:,
        net_changes: total_added - total_removed,
        first_commit_date: record.first_commit_date,
        last_commit_date: record.last_commit_date
      }
    end

    def build_unregistered_user(name)
      UnregisteredGithubUser.new(
        id: nil,
        name:,
        github_username: name,
        unregistered: true
      )
    end
  end
end
