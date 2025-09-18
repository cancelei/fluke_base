# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :validate_cloudflare_turnstile, only: [ :create ]

  private

  # Handle Turnstile validation failure
  def handle_turnstile_failure
    self.resource = resource_class.new(sign_in_params)
    resource.errors.add(:base, "Security verification failed. Please try again.")
    render :new, status: :unprocessable_entity
  end

  # Rescue from the gem's exception
  rescue_from RailsCloudflareTurnstile::Forbidden do
    handle_turnstile_failure
  end
end
