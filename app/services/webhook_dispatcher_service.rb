# frozen_string_literal: true

# Service for dispatching webhook events to subscribed endpoints
class WebhookDispatcherService
  include HTTParty
  base_uri nil # Set per-request

  # Timeout configuration
  DEFAULT_TIMEOUT = 10 # seconds
  OPEN_TIMEOUT = 5 # seconds

  def initialize(project)
    @project = project
  end

  # Dispatch an event to all active subscriptions
  # @param event_type [String] Event type (e.g., "env.updated")
  # @param payload [Hash] Event payload
  # @param resource_id [String, Integer] ID of the resource that triggered the event
  # @return [Array<WebhookDelivery>] Created delivery records
  def dispatch(event_type, payload:, resource_id:)
    subscriptions = @project.webhook_subscriptions
                            .active
                            .healthy
                            .for_event(event_type)

    return [] if subscriptions.empty?

    deliveries = []

    subscriptions.find_each do |subscription|
      delivery = create_delivery(subscription, event_type, payload, resource_id)
      deliveries << delivery

      # Enqueue async delivery job
      WebhookDeliveryJob.perform_later(delivery.id)
    end

    deliveries
  end

  # Deliver a webhook synchronously (used by job)
  # @param delivery [WebhookDelivery] The delivery to send
  # @return [Boolean] Success status
  def self.deliver(delivery)
    new(delivery.webhook_subscription.project).send_delivery(delivery)
  end

  # Send a delivery to its endpoint
  def send_delivery(delivery)
    subscription = delivery.webhook_subscription

    # Build request
    headers = build_headers(subscription, delivery)
    body = delivery.payload.to_json

    begin
      response = self.class.post(
        subscription.callback_url,
        headers:,
        body:,
        timeout: DEFAULT_TIMEOUT,
        open_timeout: OPEN_TIMEOUT
      )

      if response.success?
        delivery.record_success!(
          status_code: response.code,
          response_body: response.body
        )
        true
      else
        delivery.record_failure!(
          status_code: response.code,
          response_body: response.body
        )
        false
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      delivery.record_failure!(response_body: "Timeout: #{e.message}")
      false
    rescue StandardError => e
      delivery.record_failure!(response_body: "Error: #{e.message}")
      false
    end
  end

  # Retry all pending deliveries for the project
  def retry_pending
    WebhookDelivery
      .joins(:webhook_subscription)
      .where(webhook_subscriptions: { project_id: @project.id })
      .retryable
      .find_each do |delivery|
        WebhookDeliveryJob.perform_later(delivery.id)
      end
  end

  private

  def create_delivery(subscription, event_type, payload, resource_id)
    idempotency_key = WebhookDelivery.generate_idempotency_key(
      subscription_id: subscription.id,
      event_type:,
      resource_id:,
      timestamp: Time.current
    )

    # Check for duplicate (idempotency)
    existing = subscription.webhook_deliveries.find_by(idempotency_key:)
    return existing if existing

    subscription.webhook_deliveries.create!(
      event_type:,
      payload: build_payload(event_type, payload),
      idempotency_key:
    )
  end

  def build_payload(event_type, data)
    {
      event: event_type,
      timestamp: Time.current.iso8601,
      project_id: @project.id,
      data:
    }
  end

  def build_headers(subscription, delivery)
    headers = {
      "Content-Type" => "application/json",
      "User-Agent" => "FlukeBase-Webhook/1.0",
      "X-FlukeBase-Event" => delivery.event_type,
      "X-FlukeBase-Delivery-ID" => delivery.id.to_s,
      "X-FlukeBase-Project-ID" => @project.id.to_s
    }

    # Add HMAC signature if secret is configured
    if subscription.secret.present?
      signature = subscription.sign_payload(delivery.payload)
      headers["X-FlukeBase-Signature"] = "sha256=#{signature}"
    end

    headers
  end
end
