# frozen_string_literal: true

# Concern for switching project context and updating the UI via Turbo Streams
# Include this in any controller that needs to switch project context
# and update the context navigation bar dynamically.
#
# @example Basic usage
#   class AgreementsController < ApplicationController
#     include ProjectContextSwitchable
#
#     def show
#       @agreement = Agreement.find(params[:id])
#       @project = @agreement.project
#       switch_project_context(@project)
#     end
#   end
#
# @example With Turbo Stream response
#   def show
#     @agreement = Agreement.find(params[:id])
#     @project = @agreement.project
#     switch_project_context(@project)
#
#     respond_to do |format|
#       format.html
#       format.turbo_stream { render turbo_stream: project_context_turbo_streams }
#     end
#   end
module ProjectContextSwitchable
  extend ActiveSupport::Concern

  # Switch the project context for the current user
  # Updates both session and user record via ProjectSelectionService
  # Also updates @selected_project for immediate use in views
  #
  # @param project [Project] The project to switch to
  # @return [Boolean] true if switch was successful, false otherwise
  def switch_project_context(project)
    return false unless project && current_user

    result = ProjectSelectionService.new(current_user, session, project.id).call
    if result.success?
      @switched_project = result.value!
      # Update @selected_project so views render with the new context immediately
      @selected_project = @switched_project
    else
      @switched_project = nil
    end
    result.success?
  end

  # Generate Turbo Stream arrays for updating the project context nav
  # Call this in turbo_stream format responses after switching context
  #
  # @return [Array<Turbo::Streams::TagBuilder>] Array of turbo stream tags
  def project_context_turbo_streams
    return [] unless @switched_project

    [
      turbo_stream.replace(
        "project-context",
        partial: "shared/project_context_nav",
        locals: { selected_project: @switched_project }
      )
    ]
  end

  # Append additional turbo streams to the base context streams
  # Useful for updating page-specific content along with context nav
  #
  # @param additional_streams [Array<Turbo::Streams::TagBuilder>] Additional streams to include
  # @return [Array<Turbo::Streams::TagBuilder>] Combined turbo stream arrays
  def project_context_turbo_streams_with(*additional_streams)
    project_context_turbo_streams + additional_streams.flatten
  end

  # Check if a project context switch occurred
  #
  # @return [Boolean] true if context was switched in this request
  def project_context_switched?
    @switched_project.present?
  end

  # Get the project that was switched to
  #
  # @return [Project, nil] The switched project or nil
  def switched_project
    @switched_project
  end
end
