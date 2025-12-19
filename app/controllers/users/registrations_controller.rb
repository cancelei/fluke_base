# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [ :new, :create, :cancel ]
  before_action :validate_cloudflare_turnstile, only: [ :create ], if: -> { Rails.env.production? && RailsCloudflareTurnstile.configuration.enabled }

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    dashboard_path
  end

  private

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
