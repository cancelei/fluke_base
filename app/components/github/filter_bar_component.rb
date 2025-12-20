# frozen_string_literal: true

module Github
  # Displays filter controls for GitHub logs (branch, user, agreement toggle)
  #
  # Extracted from app/views/github_logs/_github_logs.html.erb (lines 8-98)
  #
  # Usage:
  #   <%= render Github::FilterBarComponent.new(
  #     project: project,
  #     available_branches: branches,
  #     available_users: users,
  #     selected_branch: "1",
  #     agreement_only: false,
  #     user_name: nil
  #   ) %>
  #
  class FilterBarComponent < ApplicationComponent
    # Initialize the component
    # @param project [Project] The project
    # @param available_branches [Array<Array>] Array of [id, name] pairs
    # @param available_users [Array<String>] Array of user names
    # @param selected_branch [String, nil] Currently selected branch ID
    # @param agreement_only [Boolean] Whether agreement filter is active
    # @param user_name [String, nil] Currently selected user name
    def initialize(project:, available_branches:, available_users: [], selected_branch: nil, agreement_only: false, user_name: nil)
      @project = project
      @available_branches = available_branches || []
      @available_users = available_users || []
      @selected_branch = selected_branch
      @agreement_only = agreement_only
      @user_name = user_name
    end

    # Whether to render the component
    # @return [Boolean]
    def render?
      @available_branches.any?
    end

    # Whether any filters are active
    # @return [Boolean]
    def has_filters?
      @selected_branch.present? || @agreement_only || @user_name.present?
    end

    # Get the display name for the selected branch
    # @return [String]
    def selected_branch_name
      return "All Branches" unless @selected_branch.present?

      @available_branches.find { |id, _| id == @selected_branch.to_i }&.last || "main"
    end

    # Get the display name for the selected user
    # @return [String]
    def selected_user_name
      @user_name.presence || "All Users"
    end

    # URL for clearing all filters
    # @return [String]
    def clear_filters_path
      project_github_logs_path(@project)
    end

    # URL with branch filter
    # @param branch_id [Integer, nil]
    # @return [String]
    def branch_filter_path(branch_id)
      project_github_logs_path(@project, branch: branch_id, user_name: @user_name, agreement_only: @agreement_only.presence)
    end

    # URL with user filter
    # @param name [String, nil]
    # @return [String]
    def user_filter_path(name)
      project_github_logs_path(@project, branch: @selected_branch, user_name: name, agreement_only: @agreement_only.presence)
    end

    # URL for toggling agreement filter
    # @return [String]
    def agreement_toggle_path
      project_github_logs_path(
        @project,
        branch: @selected_branch,
        user_name: @user_name,
        agreement_only: @agreement_only ? nil : true
      )
    end

    private

    attr_reader :project, :available_branches, :available_users, :selected_branch, :agreement_only, :user_name
  end
end
