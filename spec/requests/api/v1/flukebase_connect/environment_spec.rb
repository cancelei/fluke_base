# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect Environment API', type: :request do
  path '/api/v1/flukebase_connect/projects/{project_id}/environment' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'Get environment configuration' do
      tags 'Environment'
      description 'Returns environment configuration metadata for a project.'
      operationId 'getEnvironmentConfig'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :environment, in: :query, type: :string, required: false,
                enum: %w[development staging production],
                description: 'Environment name (default: development)'

      response '200', 'Environment config retrieved' do
        schema type: :object,
               properties: {
                 environment: {
                   type: :object,
                   properties: {
                     name: { type: :string, example: 'development' },
                     description: { type: :string, nullable: true },
                     last_synced_at: { type: :string, format: 'date-time', nullable: true },
                     sync_count: { type: :integer },
                     variables_count: { type: :integer }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:environment']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/environment/variables' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'Get environment variables' do
      tags 'Environment'
      description 'Returns all environment variables for a project. Used by flukebase_connect to sync .env files.'
      operationId 'getEnvironmentVariables'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :environment, in: :query, type: :string, required: false,
                enum: %w[development staging production],
                description: 'Environment name (default: development)'

      response '200', 'Variables retrieved' do
        schema type: :object,
               properties: {
                 variables: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/environment_variable' }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     environment: { type: :string },
                     count: { type: :integer }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:environment']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/environment/sync' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Record environment sync' do
      tags 'Environment'
      description 'Records that a sync occurred for analytics tracking.'
      operationId 'recordEnvironmentSync'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :sync_data, in: :body, schema: {
        type: :object,
        properties: {
          environment: { type: :string, enum: %w[development staging production] }
        }
      }

      response '200', 'Sync recorded' do
        schema type: :object,
               properties: {
                 synced: { type: :boolean },
                 environment: { type: :string },
                 synced_at: { type: :string, format: 'date-time' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:environment']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:sync_data) { { environment: 'development' } }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/batch/environment' do
    get 'Get environment variables for multiple projects' do
      tags 'Environment', 'Batch Operations'
      description 'Returns environment variables for multiple projects in a single request. Part of MPSYNC milestone.'
      operationId 'batchEnvironment'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :project_ids, in: :query, type: :array, items: { type: :integer },
                description: 'Array of project IDs'
      parameter name: :all, in: :query, type: :boolean, required: false,
                description: 'If true, returns for all accessible projects'
      parameter name: :environment, in: :query, type: :string, required: false,
                enum: %w[development staging production],
                description: 'Environment name (default: development)'

      response '200', 'Batch environment retrieved' do
        schema type: :object,
               properties: {
                 environments: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       project_id: { type: :integer },
                       project_name: { type: :string },
                       environment: { type: :string },
                       variables: { type: :array, items: { '$ref' => '#/components/schemas/environment_variable' } },
                       variables_count: { type: :integer }
                     }
                   }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     count: { type: :integer },
                     environment: { type: :string },
                     total_variables: { type: :integer }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user:, scopes: ['read:environment']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:all) { true }

        run_test!
      end
    end
  end
end
