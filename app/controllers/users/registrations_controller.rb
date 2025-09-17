# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :verify_turnstile_token, only: [ :create ]

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    dashboard_path
  end

  private

  def verify_turnstile_token
    return if Rails.env.development?
    return if Rails.application.config.turnstile[:secret_key].blank?

    # In production, Turnstile sends the token as 'cf-turnstile-response'
    # In development, we send it as 'turnstile_token'
    token = params["cf-turnstile-response"] || params[:turnstile_token]

    if token.blank?
      self.resource = build_resource(sign_up_params)
      resource.errors.add(:base, "Security verification is required. Please refresh the page and try again.")
      render :new, status: :unprocessable_entity
      return
    end

    unless TurnstileVerificationService.verify(token, request.remote_ip)
      self.resource = build_resource(sign_up_params)
      resource.errors.add(:base, "Security verification failed. Please try again.")
      render :new, status: :unprocessable_entity
    end
  end
end
