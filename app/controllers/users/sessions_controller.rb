# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :verify_turnstile_token, only: [ :create ]

  private

  def verify_turnstile_token
    return if Rails.env.development?
    return if Rails.application.config.turnstile[:secret_key].blank?

    # In production, Turnstile sends the token as 'cf-turnstile-response'
    # In development, we send it as 'turnstile_token'
    token = params["cf-turnstile-response"] || params[:turnstile_token]

    if token.blank?
      self.resource = resource_class.new(sign_in_params)
      resource.errors.add(:base, "Security verification is required. Please refresh the page and try again.")
      render :new, status: :unprocessable_entity
      return
    end

    unless TurnstileVerificationService.verify(token, request.remote_ip)
      self.resource = resource_class.new(sign_in_params)
      resource.errors.add(:base, "Security verification failed. Please try again.")
      render :new, status: :unprocessable_entity
    end
  end
end
