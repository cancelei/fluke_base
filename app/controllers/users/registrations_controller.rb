# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [:new, :create, :cancel]
  before_action :validate_cloudflare_turnstile, only: [:create], if: -> { should_validate_turnstile? }

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    dashboard_path
  end

  private

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
    self.resource = build_resource(sign_up_params)
    resource.errors.add(:base, "Security verification failed. Please try again.")
    render :new, status: :unprocessable_content
  end

  rescue_from RailsCloudflareTurnstile::Forbidden do
    handle_turnstile_failure
  end
end
