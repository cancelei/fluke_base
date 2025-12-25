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
    return unless user_signed_in? && current_user

    # Determine project id from nested routes (project_id) or direct project routes (id)
    incoming_project_id = if params[:project_id].present?
                            params[:project_id]
    elsif controller_name == "projects" && params[:id].present?
                            params[:id]
    else
                            nil
    end

    if incoming_project_id.present?
      # Use friendly_id finder to support both numeric IDs and slugs
      project = Project.friendly.find(incoming_project_id) rescue nil
      if project
        involved_as_owner = current_user.projects.include?(project)
        involved_via_initiated = current_user.initiated_agreements.where(project_id: project.id, status: "Accepted").exists?
        involved_via_received = current_user.received_agreements.where(project_id: project.id, status: "Accepted").exists?

        if involved_as_owner || involved_via_initiated || involved_via_received
          # Only call ProjectSelectionService for project owners
          if involved_as_owner
            ProjectSelectionService.new(current_user, session, project.id).call
          end
          @selected_project = project
        end
      end
    else
      # Set @selected_project from session if not set by params
      selected_project_id = current_user.selected_project_id || session[:selected_project_id]

      # Enhanced project resolution for mentors and entrepreneurs
      if selected_project_id.present?
        # Find project through ownership or agreements (unified logic for all users)
        # Include both Accepted and Completed agreement statuses
        @selected_project = current_user.projects.find_by(id: selected_project_id) ||
                           current_user.initiated_agreements
                                      .where(project_id: selected_project_id, status: %w[Accepted Completed])
                                      .first&.project ||
                           current_user.received_agreements
                                      .where(project_id: selected_project_id, status: %w[Accepted Completed])
                                      .first&.project
      end

      # Fallback: set first available project if none selected
      if @selected_project.nil? && current_user.projects.any?
        @selected_project = current_user.projects.first
        ProjectSelectionService.new(current_user, session, @selected_project.id).call if @selected_project
      end
    end
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
