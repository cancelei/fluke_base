# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect Productivity Metrics API', type: :request do
  path '/api/v1/flukebase_connect/projects/{project_id}/productivity_metrics' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'List productivity metrics' do
      tags 'Productivity Metrics'
      description 'Returns AI productivity metrics synced from flukebase_connect sessions.'
      operationId 'listProductivityMetrics'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :type, in: :query, type: :string, required: false,
                enum: %w[time_saved code_contribution task_velocity token_efficiency],
                description: 'Filter by metric type'
      parameter name: :period_type, in: :query, type: :string, required: false,
                enum: %w[session daily weekly monthly],
                description: 'Filter by period type'
      parameter name: :since, in: :query, type: :string, format: 'date-time', required: false,
                description: 'Only return metrics after this timestamp'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false,
                description: 'Items per page (max: 100)'

      response '200', 'Metrics retrieved' do
        schema type: :object,
               properties: {
                 metrics: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/productivity_metric' }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     total: { type: :integer },
                     page: { type: :integer },
                     per_page: { type: :integer },
                     pages: { type: :integer }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:api_token) { create(:api_token, user: user, scopes: ['read:metrics']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end
    end

    post 'Create productivity metric' do
      tags 'Productivity Metrics'
      description 'Creates a new productivity metric record from a flukebase_connect session.'
      operationId 'createProductivityMetric'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :metric, in: :body, schema: {
        type: :object,
        properties: {
          metric_type: { type: :string, enum: %w[time_saved code_contribution task_velocity token_efficiency] },
          period_type: { type: :string, enum: %w[session daily weekly monthly] },
          period_start: { type: :string, format: 'date-time' },
          period_end: { type: :string, format: 'date-time' },
          external_id: { type: :string, description: 'Client-side unique identifier' },
          metric_data: {
            type: :object,
            description: 'Type-specific metric data',
            example: { ai_time_ms: 5000, estimated_human_time_ms: 30000, efficiency_ratio: 6.0 }
          }
        },
        required: %w[metric_type period_type metric_data]
      }

      response '201', 'Metric created' do
        schema type: :object,
               properties: {
                 metric: { '$ref' => '#/components/schemas/productivity_metric' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:api_token) { create(:api_token, user: user, scopes: ['write:metrics']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:metric) do
          {
            metric: {
              metric_type: 'time_saved',
              period_type: 'session',
              period_start: Time.current.iso8601,
              period_end: Time.current.iso8601,
              external_id: 'session-123',
              metric_data: { ai_time_ms: 5000, estimated_human_time_ms: 30000 }
            }
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/productivity_metrics/{id}' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'
    parameter name: :id, in: :path, type: :integer, description: 'Metric ID'

    get 'Get metric details' do
      tags 'Productivity Metrics'
      description 'Returns detailed information about a specific productivity metric.'
      operationId 'getProductivityMetric'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Metric retrieved' do
        schema type: :object,
               properties: {
                 metric: { '$ref' => '#/components/schemas/productivity_metric' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:metric_record) { create(:ai_productivity_metric, project: project, user: user) }
        let(:api_token) { create(:api_token, user: user, scopes: ['read:metrics']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { metric_record.id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/productivity_metrics/summary' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'Get productivity summary' do
      tags 'Productivity Metrics'
      description 'Returns aggregated productivity summary for the dashboard.'
      operationId 'getProductivitySummary'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :period, in: :query, type: :string, required: false,
                enum: %w[day week month year],
                description: 'Summary period (default: week)'

      response '200', 'Summary retrieved' do
        schema type: :object,
               properties: {
                 summary: {
                   type: :object,
                   properties: {
                     total_time_saved_ms: { type: :integer },
                     total_tasks_completed: { type: :integer },
                     total_tokens_used: { type: :integer },
                     session_count: { type: :integer }
                   }
                 },
                 stats: {
                   type: :object,
                   nullable: true,
                   description: 'Materialized view stats if available'
                 },
                 period: { type: :string },
                 since: { type: :string, format: 'date-time' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:api_token) { create(:api_token, user: user, scopes: ['read:metrics']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/productivity_metrics/bulk_sync' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Bulk sync productivity metrics' do
      tags 'Productivity Metrics', 'Sync'
      description 'Synchronizes multiple productivity metrics in a single request for efficient batch updates.'
      operationId 'bulkSyncProductivityMetrics'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :sync_data, in: :body, schema: {
        type: :object,
        properties: {
          metrics: {
            type: :array,
            items: {
              type: :object,
              properties: {
                external_id: { type: :string, description: 'Required for sync' },
                metric_type: { type: :string },
                period_type: { type: :string },
                period_start: { type: :string, format: 'date-time' },
                period_end: { type: :string, format: 'date-time' },
                metric_data: { type: :object }
              },
              required: ['external_id']
            }
          }
        },
        required: ['metrics']
      }

      response '200', 'Sync completed' do
        schema type: :object,
               properties: {
                 sync_results: {
                   type: :object,
                   properties: {
                     created: { type: :array, items: { '$ref' => '#/components/schemas/productivity_metric' } },
                     updated: { type: :array, items: { '$ref' => '#/components/schemas/productivity_metric' } },
                     errors: { type: :array, items: { type: :object } }
                   }
                 },
                 summary: {
                   type: :object,
                   properties: {
                     created: { type: :integer },
                     updated: { type: :integer },
                     errors: { type: :integer }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:api_token) { create(:api_token, user: user, scopes: ['write:metrics']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:sync_data) do
          {
            metrics: [
              {
                external_id: 'metric-1',
                metric_type: 'time_saved',
                period_type: 'session',
                period_start: Time.current.iso8601,
                period_end: Time.current.iso8601,
                metric_data: {}
              }
            ]
          }
        end

        run_test!
      end
    end
  end
end
