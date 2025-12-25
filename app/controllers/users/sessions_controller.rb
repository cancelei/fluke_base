# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, only: [:new, :create, :destroy]
  before_action :validate_cloudflare_turnstile, only: [:create], if: -> { should_validate_turnstile? }

  # Override destroy to clear GitHub auth cookie on logout
  # This prevents automatic session restoration when user explicitly logs out
  def destroy
    clear_github_session_restore_data
    super
  end

  private

  def clear_github_session_restore_data
    # Clear the GitHub auth preference cookie so we don't auto-restore session
    cookies.delete(:github_auth_preferred)
    session.delete(:github_restore_attempted)
    session.delete(:github_session_restore)
  end

  # Validate Turnstile when enabled and a token is present
  def should_validate_turnstile?
    return false unless RailsCloudflareTurnstile.configuration.enabled

    # If no token was submitted, allow graceful degradation in development
    turnstile_response = params["cf-turnstile-response"]
    if turnstile_response.blank?
      Rails.logger.warn "Turnstile token missing - widget may have failed to load"
      return false
    end

    true
  end

  def handle_turnstile_failure
    self.resource = resource_class.new(sign_in_params)
    resource.errors.add(:base, "Security verification failed. Please try again.")

    respond_to do |format|
      format.html { render :new, status: :unprocessable_content }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("new_user", partial: "devise/sessions/form", locals: { resource: })
      }
    end
  end

  rescue_from RailsCloudflareTurnstile::Forbidden do
    handle_turnstile_failure
  end
end
