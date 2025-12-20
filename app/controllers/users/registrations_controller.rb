# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [:new, :create, :cancel]
  before_action :validate_cloudflare_turnstile, only: [:create], if: -> { should_validate_turnstile? }

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    dashboard_path
  end

  private

  # Only validate Turnstile if:
  # 1. We're in production
  # 2. Turnstile is enabled in the gem config
  # 3. A Turnstile response token was actually submitted (meaning the widget loaded)
  def should_validate_turnstile?
    return false unless Rails.env.production?
    return false unless RailsCloudflareTurnstile.configuration.enabled

    # If no token was submitted, Turnstile likely failed to load on the client
    # Allow form submission in this case (graceful degradation)
    turnstile_response = params["cf-turnstile-response"]
    if turnstile_response.blank?
      Rails.logger.warn "Turnstile token missing - widget may have failed to load for user"
      return false
    end

    true
  end

  # Handle Turnstile validation failure
  def handle_turnstile_failure
    self.resource = build_resource(sign_up_params)
    resource.errors.add(:base, "Security verification failed. Please try again.")
    render :new, status: :unprocessable_content
  end

  # Rescue from the gem's exception
  rescue_from RailsCloudflareTurnstile::Forbidden do
    handle_turnstile_failure
  end
end
