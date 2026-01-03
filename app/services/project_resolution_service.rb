# frozen_string_literal: true

# Service for resolving the current project based on params, session, and user
class ProjectResolutionService < ApplicationService
  def initialize(user, params, session)
    @user = user
    @params = params
    @session = session
  end

  def call
    return nil unless @user

    resolve_from_params || resolve_from_session || resolve_fallback
  end

  private

  def resolve_from_params
    incoming_id = incoming_project_id
    return nil if incoming_id.blank?

    project = Project.friendly.find(incoming_id) rescue nil
    return nil unless project

    if authorized?(project)
      # Only call ProjectSelectionService for project owners to persist selection
      if @user.projects.include?(project)
        ProjectSelectionService.new(@user, @session, project.id).call
      end
      project
    end
  end

  def resolve_from_session
    selected_id = @user.selected_project_id || @session[:selected_project_id]
    return nil if selected_id.blank?

    # Unified logic to find project via ownership or agreements
    @user.projects.find_by(id: selected_id) ||
      @user.initiated_agreements.where(project_id: selected_id, status: %w[Accepted Completed]).take&.project ||
      @user.received_agreements.where(project_id: selected_id, status: %w[Accepted Completed]).take&.project
  end

  def resolve_fallback
    return nil unless @user.projects.any?

    project = @user.projects.order(:created_at).first
    ProjectSelectionService.new(@user, @session, project.id).call if project
    project
  end

  def incoming_project_id
    if @params[:project_id].present?
      @params[:project_id]
    elsif @params[:controller] == "projects" && @params[:id].present?
      @params[:id]
    end
  end

  def authorized?(project)
    @user.projects.include?(project) ||
      project.has_active_agreement_with?(@user)
  end
end
