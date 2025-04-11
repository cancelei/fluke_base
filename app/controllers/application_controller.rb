class ApplicationController < ActionController::Base
  include CanCan::ControllerAdditions
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_selected_project

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :role_id ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :role_id ])
  end

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  private

  def set_selected_project
    return unless user_signed_in?

    if params[:project_id].present?
      # Update selected project if a new one is selected
      session[:selected_project_id] = params[:project_id]
    elsif session[:selected_project_id].present?
      # Verify the project still exists and user still has access
      @selected_project = current_user.projects.find_by(id: session[:selected_project_id])
      session[:selected_project_id] = nil unless @selected_project
    end

    # Set default project if none is selected
    if session[:selected_project_id].nil? && current_user.projects.any?
      @selected_project = current_user.projects.first
      session[:selected_project_id] = @selected_project.id
    end
  end

  helper_method :selected_project
  def selected_project
    @selected_project
  end
end
