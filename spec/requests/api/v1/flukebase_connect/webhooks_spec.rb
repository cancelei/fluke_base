# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect Webhooks API', type: :request do
  path '/api/v1/flukebase_connect/projects/{project_id}/webhooks' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'List webhook subscriptions' do
      tags 'Webhooks'
      description 'Returns all webhook subscriptions for a project.'
      operationId 'listWebhooks'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Webhooks retrieved' do
        schema type: :object,
               properties: {
                 webhooks: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/webhook' }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     total: { type: :integer },
                     active: { type: :integer }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:webhooks']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end
    end

    post 'Create webhook subscription' do
      tags 'Webhooks'
      description 'Creates a new webhook subscription for receiving real-time notifications.'
      operationId 'createWebhook'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :webhook, in: :body, schema: {
        type: :object,
        properties: {
          callback_url: { type: :string, format: :uri, example: 'https://example.com/webhook' },
          events: {
            type: :array,
            items: { type: :string },
            example: %w[env.updated memory.created]
          },
          active: { type: :boolean, default: true }
        },
        required: %w[callback_url events]
      }

      response '201', 'Webhook created' do
        schema '$ref' => '#/components/schemas/webhook'

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: ['write:webhooks']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:webhook) { { callback_url: 'https://example.com/webhook', events: ['env.updated'] } }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/webhooks/{id}' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'
    parameter name: :id, in: :path, type: :integer, description: 'Webhook ID'

    get 'Get webhook details' do
      tags 'Webhooks'
      description 'Returns detailed information about a webhook subscription including secret.'
      operationId 'getWebhook'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Webhook retrieved' do
        schema type: :object,
               properties: {
                 webhook: { '$ref' => '#/components/schemas/webhook' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:webhook_record) { create(:webhook_subscription, project:) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:webhooks']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { webhook_record.id }

        run_test!
      end
    end

    put 'Update webhook' do
      tags 'Webhooks'
      description 'Updates a webhook subscription.'
      operationId 'updateWebhook'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :webhook, in: :body, schema: {
        type: :object,
        properties: {
          callback_url: { type: :string, format: :uri },
          events: { type: :array, items: { type: :string } },
          active: { type: :boolean }
        }
      }

      response '200', 'Webhook updated' do
        schema '$ref' => '#/components/schemas/webhook'

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:webhook_record) { create(:webhook_subscription, project:) }
        let(:api_token) { create(:api_token, user:, scopes: ['write:webhooks']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { webhook_record.id }
        let(:webhook) { { active: false } }

        run_test!
      end
    end

    delete 'Delete webhook' do
      tags 'Webhooks'
      description 'Deletes a webhook subscription.'
      operationId 'deleteWebhook'
      security [bearer_auth: []]

      response '200', 'Webhook deleted' do
        schema type: :object,
               properties: {
                 deleted: { type: :boolean }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:webhook_record) { create(:webhook_subscription, project:) }
        let(:api_token) { create(:api_token, user:, scopes: ['write:webhooks']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { webhook_record.id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/webhooks/{id}/deliveries' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'
    parameter name: :id, in: :path, type: :integer, description: 'Webhook ID'

    get 'Get webhook delivery history' do
      tags 'Webhooks'
      description 'Returns recent delivery attempts for a webhook.'
      operationId 'getWebhookDeliveries'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum deliveries to return (default: 50)'

      response '200', 'Deliveries retrieved' do
        schema type: :object,
               properties: {
                 deliveries: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       event_type: { type: :string },
                       status_code: { type: :integer, nullable: true },
                       attempt_count: { type: :integer },
                       delivered: { type: :boolean },
                       delivered_at: { type: :string, format: 'date-time', nullable: true },
                       created_at: { type: :string, format: 'date-time' }
                     }
                   }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     total: { type: :integer },
                     pending: { type: :integer },
                     delivered: { type: :integer }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:webhook_record) { create(:webhook_subscription, project:) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:webhooks']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { webhook_record.id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/webhooks/events' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'List available webhook events' do
      tags 'Webhooks'
      description 'Returns all available webhook event types and their descriptions.'
      operationId 'listWebhookEvents'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Events listed' do
        schema type: :object,
               properties: {
                 events: {
                   type: :array,
                   items: { type: :string },
                   example: %w[env.created env.updated env.deleted milestone.created memory.created]
                 },
                 descriptions: {
                   type: :object,
                   additionalProperties: { type: :string }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:webhooks']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end
    end
  end
end
