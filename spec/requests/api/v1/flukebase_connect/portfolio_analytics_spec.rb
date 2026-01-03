# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect Portfolio Analytics API', type: :request do
  path '/api/v1/flukebase_connect/portfolio/summary' do
    get 'Get portfolio productivity summary' do
      tags 'Portfolio Analytics'
      description 'Returns aggregated productivity metrics across all accessible projects.'
      operationId 'getPortfolioSummary'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :period, in: :query, type: :integer, required: false,
                description: 'Period in days (default: 30, max: 365)'

      response '200', 'Summary retrieved' do
        schema type: :object,
               properties: {
                 portfolio: {
                   type: :object,
                   properties: {
                     projects_count: { type: :integer },
                     total_time_saved_hours: { type: :number },
                     total_tasks_completed: { type: :integer },
                     total_tokens_used: { type: :integer },
                     total_sessions: { type: :integer },
                     estimated_cost_usd: { type: :number },
                     active_projects: { type: :integer },
                     top_project: {
                       type: :object,
                       properties: {
                         id: { type: :integer },
                         name: { type: :string },
                         time_saved_hours: { type: :number }
                       }
                     }
                   }
                 },
                 generated_at: { type: :string, format: 'date-time' }
               }

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:metrics']) }
        let(:Authorization) { "Bearer #{api_token.token}" }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/portfolio/compare' do
    get 'Compare projects by productivity' do
      tags 'Portfolio Analytics'
      description 'Returns a ranked list of projects by productivity metrics for comparison.'
      operationId 'compareProjects'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :period, in: :query, type: :integer, required: false,
                description: 'Period in days (default: 30)'
      parameter name: :sort_by, in: :query, type: :string, required: false,
                enum: %w[time_saved tasks_completed tokens_used sessions_count cost],
                description: 'Sort metric (default: time_saved)'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum projects to return (default: 10, max: 50)'

      response '200', 'Comparison retrieved' do
        schema type: :object,
               properties: {
                 projects: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       name: { type: :string },
                       rank: { type: :integer },
                       time_saved_hours: { type: :number },
                       tasks_completed: { type: :integer },
                       tokens_used: { type: :integer },
                       sessions_count: { type: :integer },
                       estimated_cost_usd: { type: :number },
                       efficiency_score: { type: :number }
                     }
                   }
                 },
                 sort_by: { type: :string },
                 period_days: { type: :integer }
               }

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:metrics']) }
        let(:Authorization) { "Bearer #{api_token.token}" }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/portfolio/trends' do
    get 'Get productivity trends' do
      tags 'Portfolio Analytics'
      description 'Returns time-series productivity data for trend analysis.'
      operationId 'getPortfolioTrends'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :period, in: :query, type: :integer, required: false,
                description: 'Period in days (default: 30, min: 7)'
      parameter name: :granularity, in: :query, type: :string, required: false,
                enum: %w[daily weekly],
                description: 'Data point granularity (default: daily)'

      response '200', 'Trends retrieved' do
        schema type: :object,
               properties: {
                 trends: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       date: { type: :string, format: :date },
                       time_saved_hours: { type: :number },
                       tasks_completed: { type: :integer },
                       tokens_used: { type: :integer },
                       sessions_count: { type: :integer },
                       active_projects: { type: :integer }
                     }
                   }
                 },
                 granularity: { type: :string },
                 period_days: { type: :integer }
               }

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:metrics']) }
        let(:Authorization) { "Bearer #{api_token.token}" }

        run_test!
      end
    end
  end
end
