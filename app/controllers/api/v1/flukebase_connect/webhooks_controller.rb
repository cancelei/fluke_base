# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      class WebhooksController < BaseController
        before_action :set_project
        before_action :set_subscription, only: %i[show update destroy deliveries]
        before_action -> { require_scope!("write:webhooks") }, only: %i[create update destroy]
        before_action -> { require_scope!("read:webhooks") }, only: %i[index show deliveries]

        # GET /api/v1/flukebase_connect/projects/:project_id/webhooks
        def index
          subscriptions = @project.webhook_subscriptions

          render_success(
            webhooks: subscriptions.map { |s| subscription_to_hash(s) },
            meta: {
              total: subscriptions.count,
              active: subscriptions.active.count
            }
          )
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/webhooks/:id
        def show
          render_success(webhook: subscription_to_hash(@subscription, include_secret: true))
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/webhooks
        def create
          subscription = @project.webhook_subscriptions.build(subscription_params)
          subscription.api_token = current_api_token

          if subscription.save
            render_success(
              { webhook: subscription_to_hash(subscription, include_secret: true) },
              status: :created
            )
          else
            render_error(
              "Failed to create webhook subscription",
              errors: subscription.errors.full_messages
            )
          end
        end

        # PUT /api/v1/flukebase_connect/projects/:project_id/webhooks/:id
        def update
          if @subscription.update(subscription_params)
            render_success(webhook: subscription_to_hash(@subscription))
          else
            render_error(
              "Failed to update webhook subscription",
              errors: @subscription.errors.full_messages
            )
          end
        end

        # DELETE /api/v1/flukebase_connect/projects/:project_id/webhooks/:id
        def destroy
          @subscription.destroy!
          render_success(deleted: true)
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/webhooks/:id/deliveries
        def deliveries
          deliveries = @subscription.webhook_deliveries
                                    .recent
                                    .limit(params[:limit] || 50)

          render_success(
            deliveries: deliveries.map { |d| delivery_to_hash(d) },
            meta: {
              total: @subscription.webhook_deliveries.count,
              pending: @subscription.webhook_deliveries.pending.count,
              delivered: @subscription.webhook_deliveries.delivered.count
            }
          )
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/webhooks/events
        def events
          render_success(
            events: WebhookSubscription::EVENTS,
            descriptions: {
              "env.created" => "Environment variable created",
              "env.updated" => "Environment variable updated",
              "env.deleted" => "Environment variable deleted",
              "milestone.created" => "Milestone created",
              "milestone.updated" => "Milestone updated",
              "milestone.completed" => "Milestone marked as completed",
              "memory.created" => "Memory created",
              "memory.updated" => "Memory updated",
              "memory.synced" => "Memory synced from flukebase_connect",
              "agreement.updated" => "Agreement status changed"
            }
          )
        end

        private

        def set_project
          @project = current_user.accessible_projects.find(params[:project_id])
        rescue ActiveRecord::RecordNotFound
          forbidden
        end

        def set_subscription
          @subscription = @project.webhook_subscriptions.find(params[:id])
        end

        def subscription_params
          params.require(:webhook).permit(
            :callback_url,
            :active,
            events: []
          )
        end

        def subscription_to_hash(subscription, include_secret: false)
          hash = {
            id: subscription.id,
            callback_url: subscription.callback_url,
            events: subscription.events,
            active: subscription.active,
            healthy: subscription.healthy?,
            failure_count: subscription.failure_count,
            last_success_at: subscription.last_success_at&.iso8601,
            last_failure_at: subscription.last_failure_at&.iso8601,
            created_at: subscription.created_at.iso8601,
            updated_at: subscription.updated_at.iso8601
          }

          hash[:secret] = subscription.secret if include_secret

          hash
        end

        def delivery_to_hash(delivery)
          {
            id: delivery.id,
            event_type: delivery.event_type,
            status_code: delivery.status_code,
            attempt_count: delivery.attempt_count,
            delivered: delivery.delivered?,
            delivered_at: delivery.delivered_at&.iso8601,
            next_retry_at: delivery.next_retry_at&.iso8601,
            created_at: delivery.created_at.iso8601
          }
        end
      end
    end
  end
end
