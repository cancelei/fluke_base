# frozen_string_literal: true

# Background job for delivering webhooks
class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  # Retry with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(delivery_id)
    delivery = WebhookDelivery.find_by(id: delivery_id)
    return unless delivery

    # Skip if already delivered or not retryable
    return if delivery.delivered?
    return unless delivery.retryable?

    # Deliver the webhook
    WebhookDispatcherService.deliver(delivery)
  end
end
