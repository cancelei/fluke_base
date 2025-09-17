# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :verify_turnstile_token, only: [ :create ]

  private

  def verify_turnstile_token
    return if Rails.application.config.turnstile[:secret_key].blank?

    token = params[:turnstile_token]
    unless TurnstileVerificationService.verify(token, request.remote_ip)
      resource = resource_class.new(sign_in_params)
      resource.errors.add(:base, "Please complete the security verification.")
      render :new, status: :unprocessable_entity
    end
  end
end
