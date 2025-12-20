# frozen_string_literal: true

module Github
  # Displays empty state when no GitHub activity is found
  #
  # Extracted from app/views/github_logs/_empty_state.html.erb
  #
  # Usage:
  #   <%= render Github::EmptyStateComponent.new(project: project, current_user: current_user) %>
  #
  class EmptyStateComponent < ApplicationComponent
    # Initialize the component
    # @param project [Project] The project
    # @param current_user [User, nil] The current logged-in user
    # @param job_context [Boolean] Whether this is rendered from a background job
    def initialize(project:, current_user: nil, job_context: false)
      @project = project
      @current_user = current_user
      @job_context = job_context
    end

    # Whether to show troubleshooting tips
    # @return [Boolean]
    def show_troubleshooting?
      return false if job_context?
      current_user && can_manage?
    end

    # Whether this is being rendered from a job context
    # @return [Boolean]
    def job_context?
      @job_context
    end

    # Whether the current user can manage the project
    # @return [Boolean]
    def can_manage?
      return false unless @current_user

      @project.user == @current_user ||
        @project.agreements.active.joins(:agreement_participants)
                .exists?(agreement_participants: { user_id: @current_user.id })
    end

    # Message to display based on context
    # @return [String]
    def message
      if job_context?
        "This project doesn't have any GitHub activity yet or the repository is not properly configured."
      elsif can_manage?
        "The repository might be empty or there was an issue accessing it."
      else
        "This project doesn't have any GitHub activity yet or the repository is not properly configured."
      end
    end

    private

    attr_reader :project, :current_user
  end
end
