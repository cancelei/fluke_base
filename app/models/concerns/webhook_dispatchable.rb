# frozen_string_literal: true

# Concern for models that can trigger webhook events
#
# Include this concern in models that should dispatch webhooks
# when they are created, updated, or destroyed.
#
# Usage:
#   class EnvironmentVariable < ApplicationRecord
#     include WebhookDispatchable
#
#     webhook_events create: "env.created",
#                    update: "env.updated",
#                    destroy: "env.deleted"
#   end
#
module WebhookDispatchable
  extend ActiveSupport::Concern

  included do
    class_attribute :_webhook_events, default: {}

    after_commit :dispatch_create_webhook, on: :create
    after_commit :dispatch_update_webhook, on: :update
    after_commit :dispatch_destroy_webhook, on: :destroy
  end

  class_methods do
    # Configure webhook events for this model
    # @param events [Hash] Hash mapping :create, :update, :destroy to event names
    def webhook_events(events = {})
      self._webhook_events = events.stringify_keys
    end
  end

  private

  def dispatch_create_webhook
    dispatch_webhook(:create)
  end

  def dispatch_update_webhook
    dispatch_webhook(:update)
  end

  def dispatch_destroy_webhook
    dispatch_webhook(:destroy)
  end

  def dispatch_webhook(action)
    event_type = self.class._webhook_events[action.to_s]
    return unless event_type.present?

    project = webhook_project
    return unless project

    dispatcher = WebhookDispatcherService.new(project)
    dispatcher.dispatch(
      event_type,
      payload: webhook_payload,
      resource_id: webhook_resource_id
    )
  rescue StandardError => e
    Rails.logger.error("Webhook dispatch failed: #{e.message}")
    # Don't raise - webhook failures shouldn't break the main operation
  end

  # Override in including class to customize the project
  def webhook_project
    return project if respond_to?(:project)
    return self if is_a?(Project)

    nil
  end

  # Override in including class to customize the payload
  def webhook_payload
    if respond_to?(:to_api_hash)
      to_api_hash
    else
      attributes.except("created_at", "updated_at")
    end
  end

  # Override in including class to customize the resource ID
  def webhook_resource_id
    id
  end
end
