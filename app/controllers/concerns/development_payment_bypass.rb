# frozen_string_literal: true

# Development Payment Bypass
#
# In development environment, this concern bypasses any payment/subscription checks
# to allow full access to the application for testing purposes.
#
# Usage in controllers:
#   include DevelopmentPaymentBypass
#   before_action :check_subscription, unless: :bypass_payment_in_development?
#
# This ensures that:
# - Production: Full subscription checks are enforced
# - Staging: Full subscription checks are enforced
# - Development: All features accessible without payment
# - Test: All features accessible without payment
module DevelopmentPaymentBypass
  extend ActiveSupport::Concern

  included do
    # Make the bypass method available to views as well
    helper_method :bypass_payment_in_development?
  end

  private

  # Returns true if we should bypass payment checks
  # Only bypasses in development and test environments
  def bypass_payment_in_development?
    Rails.env.development? || Rails.env.test?
  end

  # Returns true if user has active subscription OR we're in dev/test
  def has_active_subscription_or_bypass?
    bypass_payment_in_development? || current_user&.payment_processor&.subscribed?
  end

  # Use this method instead of requiring subscription directly
  # It will automatically bypass in development/test
  def require_active_subscription_unless_bypass
    return if bypass_payment_in_development?

    unless current_user&.payment_processor&.subscribed?
      redirect_to pricing_path, alert: "Please subscribe to access this feature"
    end
  end
end
