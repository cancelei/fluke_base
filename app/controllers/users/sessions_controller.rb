# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, only: [:new, :create]
  before_action :validate_cloudflare_turnstile, only: [:create], if: -> { should_validate_turnstile? }

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
    self.resource = resource_class.new(sign_in_params)
    resource.errors.add(:base, "Security verification failed. Please try again.")

    respond_to do |format|
      format.html { render :new, status: :unprocessable_content }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("new_user", partial: "devise/sessions/form", locals: { resource: })
      }
    end
  end

  # Rescue from the gem's exception
  rescue_from RailsCloudflareTurnstile::Forbidden do
    handle_turnstile_failure
  end
end
