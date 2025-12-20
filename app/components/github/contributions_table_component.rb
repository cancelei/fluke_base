# frozen_string_literal: true

module Github
  # Displays the contributions table with all contributors
  #
  # Extracted from app/views/github_logs/_contributions_section.html.erb
  #
  # Usage:
  #   <%= render Github::ContributionsTableComponent.new(
  #     contributions: contributions,
  #     project: project
  #   ) %>
  #
  class ContributionsTableComponent < ApplicationComponent
    # Initialize the component
    # @param contributions [Array<Hash>] Array of contribution data
    # @param project [Project] The project for owner badge display
    # @param loading [Boolean] Show loading state
    def initialize(contributions:, project:, loading: false)
      @contributions = contributions || []
      @project = project
      @loading = loading
    end

    # Whether to render the component
    # @return [Boolean]
    def render?
      @contributions.present? || loading?
    end

    # Whether to show loading state
    # @return [Boolean]
    def loading?
      @loading || @contributions.blank?
    end

    # Render a contributor row
    # @param contribution [Hash] Contribution data
    # @return [String] Rendered HTML
    def contributor_row(contribution)
      render ContributorRowComponent.new(
        contribution:,
        project: @project
      )
    end

    private

    attr_reader :contributions, :project
  end
end
