# frozen_string_literal: true

# Service for selecting a project for the current user
class ProjectSelectionService < ApplicationService
  def initialize(user, session, project_id)
    @user = user
    @session = session
    @project_id = project_id
  end

  # @return [Dry::Monads::Result] Success(project) or Failure(error)
  def call
    return failure_result(:not_found, "Project not found") unless project

    update_user_selection
    update_session
    Success(project)
  end

  def project
    @project ||= Project.find_by(id: @project_id)
  end

  private

  def update_user_selection
    @user.update(selected_project_id: project.id)
  end

  def update_session
    @session[:selected_project_id] = project.id
  end
end
