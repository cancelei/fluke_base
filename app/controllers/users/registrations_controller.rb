# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :verify_turnstile_token, only: [ :create ]

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    dashboard_path
  end

  private

  def verify_turnstile_token
    return if Rails.application.config.turnstile[:secret_key].blank?

    token = params[:turnstile_token]
    unless TurnstileVerificationService.verify(token, request.remote_ip)
      self.resource = build_resource(sign_up_params)
      resource.errors.add(:base, "Please complete the security verification.")
      render :new, status: :unprocessable_entity
    end
  end
end
