# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :validate_cloudflare_turnstile, only: [ :create ], if: -> { RailsCloudflareTurnstile.configuration.enabled }

  private

  # Handle Turnstile validation failure
  def handle_turnstile_failure
    self.resource = resource_class.new(sign_in_params)
    resource.errors.add(:base, "Security verification failed. Please try again.")

    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("new_user", partial: "devise/sessions/form", locals: { resource: resource })
      }
    end
  end

  # Rescue from the gem's exception
  rescue_from RailsCloudflareTurnstile::Forbidden do
    handle_turnstile_failure
  end
end
