class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization
  include RailsCloudflareTurnstile::ControllerHelpers
  include GithubSessionRestoration
  # Allow browsers with reasonable modern feature support while not being overly restrictive
  # More lenient for mobile browsers - block only IE
  allow_browser versions: { chrome: 90, safari: 13, firefox: 90, opera: 75, ie: false }
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
  # Role requirement methods removed - all users have access to all features

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error

  helper_method :selected_project, :present

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :github_username, :github_token, :turnstile_token])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :github_username, :github_token, :turnstile_token])
  end

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  private

  def set_selected_project
    @selected_project = ProjectResolutionService.new(current_user, params, session).call
  end

  def selected_project
    @selected_project
  end

  # Acting as mentor concept removed - all users have equal access

  def user_not_authorized
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = "You are not authorized to perform this action."
        render turbo_stream: turbo_stream.prepend(
          "flash_messages",
          partial: "shared/flash_message",
          locals: { type: "alert", message: flash.now[:alert] }
        )
      end
      format.html do
        flash[:alert] = "You are not authorized to perform this action."
        redirect_back(fallback_location: root_path)
      end
    end
  end

  def handle_csrf_error
    Rails.logger.warn "[ApplicationController] CSRF Token verification failed. Redirecting user to refresh token."
    # Don't reset entire session - the redirect will generate a fresh CSRF token
    # Resetting session here can cause cascading CSRF failures on retry
    respond_to do |format|
      format.html do
        flash[:alert] = "Your session has expired. Please try again."
        redirect_to new_user_session_path
      end
      format.any { head :unprocessable_content }
    end
  end

  def present(object, with: nil)
    if with
      with.new(object, view_context)
    else
      presenter_class = "#{object.class.name}Presenter".constantize
      presenter_class.new(object, view_context)
    end
  end
  helper_method :present

  # Toast notification helpers for controllers

  # Add a toast notification to flash for next request
  def toast_flash(type, message, **)
    flash[:toast] ||= []
    flash[:toast] <<({ type:, message:, ** })
  end

  # Render a toast notification via Turbo Stream
  def render_toast_stream(type, message, **options)
    render turbo_stream: turbo_stream.after("body", render_to_string(
      "shared/toast_notification",
      locals: { type:, message:, **options }
    ))
  end

  # Convenience methods for different toast types
  def toast_success(message, **)
    toast_flash(:success, message, **)
  end

  def toast_error(message, **)
    toast_flash(:error, message, **)
  end

  def toast_info(message, **)
    toast_flash(:info, message, **)
  end

  def toast_warning(message, **)
    toast_flash(:warning, message, **)
  end


  # Turbo Stream toast methods
  def stream_toast_success(message, **)
    render_toast_stream(:success, message, **)
  end

  def stream_toast_error(message, **)
    render_toast_stream(:error, message, **)
  end

  def stream_toast_info(message, **)
    render_toast_stream(:info, message, **)
  end

  def stream_toast_warning(message, **)
    render_toast_stream(:warning, message, **)
  end
end
