class ApplicationController < ActionController::Base
  include CanCan::ControllerAdditions
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

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
end
