class ApplicationController < ActionController::Base
  include CanCan::ControllerAdditions
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_selected_project

  # DRY helper: Find resource by klass and param, or redirect with alert
  def find_resource_or_redirect(klass, param_key, redirect_path, alert_message)
    resource = klass.find_by(id: params[param_key])
    unless resource
      redirect_to redirect_path, alert: alert_message and return
    end
    resource
  end

  # DRY helper: Require role or redirect
  def require_role!(role_name, redirect_path, alert_message)
    unless current_user.has_role?(role_name)
      redirect_to redirect_path, alert: alert_message and return
    end
  end

  rescue_from CanCan::AccessDenied, with: :user_not_authorized

  helper_method :selected_project, :acting_as_mentor?, :present

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :role_id, :github_username, :github_token ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :role_id, :github_username, :github_token ])
  end

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  private

  def set_selected_project
    return unless user_signed_in?

    if params[:project_id].present?
      project = Project.find_by(id: params[:project_id])
      if project && current_user.projects.include?(project)
        ProjectSelectionService.new(current_user, session, project.id).call
        @selected_project = project
      end
    else
      # Set @selected_project from session if not set by params
      selected_project_id = session[:selected_project_id] || current_user.selected_project_id
      @selected_project = current_user.projects.find_by(id: selected_project_id) if selected_project_id.present?

      if @selected_project.nil? && current_user.projects.any? && !acting_as_mentor?
        @selected_project = current_user.projects.first
        session[:selected_project_id] = @selected_project.id if @selected_project
      end
    end
  end

  def selected_project
    @selected_project
  end

  def acting_as_mentor?
    session[:acting_as_mentor].present? && current_user.has_role?(:mentor)
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  def present(object, with: nil)
    if with
      with.new(object, view_context)
    else
      presenter_class = "#{object.class.name}Presenter".constantize
      presenter_class.new(object, view_context)
    end
  end
end
