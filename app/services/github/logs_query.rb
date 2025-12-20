# frozen_string_literal: true

module Github
  # Query object for filtering and retrieving GitHub logs
  #
  # Consolidates filtering logic that was duplicated between:
  # - GithubLogsController#index (lines 13-39)
  # - GithubLogsDataService (lines 67-82)
  #
  # Usage:
  #   query = Github::LogsQuery.new(project: project, params: { branch: "1", agreement_only: true })
  #   query.recent_commits(page: 1)  # => paginated commits
  #   query.stats_query              # => query for statistics (distinct)
  #   query.available_users          # => unique contributor names
  #
  class LogsQuery
    attr_reader :project, :params

    # Initialize the query
    # @param project [Project] The project to query logs for
    # @param params [Hash] Filter parameters
    # @option params [String, Integer] :branch Branch ID to filter by
    # @option params [Boolean, String] :agreement_only Filter to agreement participants only
    # @option params [String] :user_name Filter by unregistered user name
    def initialize(project:, params: {})
      @project = project
      @params = params.to_h.with_indifferent_access
    end

    # Get recent commits with pagination
    # @param page [Integer] Page number
    # @param per_page [Integer] Items per page
    # @return [ActiveRecord::Relation] Paginated commits
    def recent_commits(page: 1, per_page: 15)
      apply_filters(base_query)
        .order(commit_date: :desc)
        .page(page)
        .per(per_page)
    end

    # Get base query for statistics (uses distinct to avoid double-counting)
    # @return [ActiveRecord::Relation]
    def stats_query
      apply_filters(project.github_logs).distinct
    end

    # Get unique unregistered user names from filtered results
    # @return [Array<String>]
    def available_users
      stats_query.pluck(:unregistered_user_name).compact.uniq.sort
    end

    # Get available branches for dropdown
    # @return [Array<Array>] Array of [id, branch_name] pairs
    def available_branches
      puts "=====================#{params.inspect}======================="
      puts "===================#{params[:user_name]}========================="
      puts "============================================"
      project.github_branches.pluck(:id, :branch_name).compact.sort_by { |_, name| params[:user_name].to_s }
    end

    # Selected branch ID from params
    # @return [String, nil]
    def selected_branch
      params[:branch].presence
    end

    # Whether agreement-only filter is active
    # @return [Boolean]
    def agreement_only?
      params[:agreement_only].present?
    end

    # Selected user name filter
    # @return [String, nil]
    def user_name
      params[:user_name].presence
    end

    # Get agreement participant user IDs
    # @return [Array<Integer>, nil]
    def agreement_user_ids
      return nil unless agreement_only?

      @agreement_user_ids ||= project.mentorships
        .where(status: "Accepted")
        .joins(:agreement_participants)
        .pluck("agreement_participants.user_id")
        .flatten
        .uniq
    end

    # Check if any filters are active
    # @return [Boolean]
    def has_filters?
      selected_branch.present? || agreement_only? || user_name.present?
    end

    # Get selected branch name for display
    # @return [String]
    def selected_branch_name
      return "All Branches" unless selected_branch.present?

      available_branches.find { |id, _| id == selected_branch.to_i }&.last || "main"
    end

    private

    def base_query
      project.github_logs.includes(:user, :github_branch_logs)
    end

    def apply_filters(query)
      query = apply_branch_filter(query)
      query = apply_user_name_filter(query)
      query = apply_agreement_filter(query)
      query
    end

    def apply_branch_filter(query)
      return query unless selected_branch.present? && selected_branch.to_i != 0

      # Need to join github_branch_logs for branch filtering
      if query.joins_values.none? { |j| j.to_s.include?("github_branch_logs") }
        query = query.joins(:github_branch_logs)
      end

      query.where(github_branch_logs: { github_branch_id: selected_branch })
    end

    def apply_user_name_filter(query)
      return query unless user_name.present?

      query.where(unregistered_user_name: user_name)
    end

    def apply_agreement_filter(query)
      return query unless agreement_only? && agreement_user_ids.present?

      query.where(user_id: agreement_user_ids)
    end
  end
end
