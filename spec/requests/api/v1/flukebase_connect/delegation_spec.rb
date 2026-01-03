# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect Delegation API', type: :request do
  path '/api/v1/flukebase_connect/projects/{project_id}/delegation/status' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'Get delegation status' do
      tags 'Delegation'
      description 'Returns container pool status, active sessions, and pending delegable tasks.'
      operationId 'getDelegationStatus'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Status retrieved' do
        schema type: :object,
               properties: {
                 pool: { '$ref' => '#/components/schemas/container_pool' },
                 sessions: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/container_session' }
                 },
                 pending_tasks: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/wedo_task' }
                 },
                 active_delegations: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/delegation_request' }
                 },
                 stats: {
                   type: :object,
                   properties: {
                     total_tasks: { type: :integer },
                     agent_capable_tasks: { type: :integer },
                     pending_delegable: { type: :integer },
                     active_sessions: { type: :integer },
                     idle_sessions: { type: :integer }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let!(:pool) { create(:container_pool, project: project) }
        let(:api_token) { create(:api_token, user: user, scopes: ['read:delegation']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end

      response '404', 'No pool configured' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'no_pool' },
                 message: { type: :string },
                 create_pool_url: { type: :string }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:api_token) { create(:api_token, user: user, scopes: ['read:delegation']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/delegation/pool' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Create or update container pool' do
      tags 'Delegation'
      description 'Configures the container pool for smart delegation.'
      operationId 'createDelegationPool'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :pool_config, in: :body, schema: {
        type: :object,
        properties: {
          warm_pool_size: { type: :integer, description: 'Number of warm containers to maintain' },
          max_pool_size: { type: :integer, description: 'Maximum containers allowed' },
          context_threshold_percent: { type: :integer, description: 'Context % that triggers handoff' },
          auto_delegate_enabled: { type: :boolean, description: 'Enable automatic task delegation' },
          skip_user_required: { type: :boolean, description: 'Skip tasks requiring user input' },
          config: { type: :object, description: 'Additional configuration' }
        }
      }

      response '200', 'Pool configured' do
        schema type: :object,
               properties: {
                 pool: { '$ref' => '#/components/schemas/container_pool' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:api_token) { create(:api_token, user: user, scopes: ['write:delegation']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:pool_config) { { warm_pool_size: 2, max_pool_size: 5 } }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/delegation/claim' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Claim task for execution' do
      tags 'Delegation'
      description 'Atomically claims a task for a container session to prevent double-delegation.'
      operationId 'claimTask'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :claim_request, in: :body, schema: {
        type: :object,
        properties: {
          task_id: { type: :string, description: 'WeDo task ID to claim' },
          session_id: { type: :string, description: 'Container session ID' }
        },
        required: %w[task_id session_id]
      }

      response '200', 'Task claimed' do
        schema type: :object,
               properties: {
                 claimed: { type: :boolean },
                 task: { '$ref' => '#/components/schemas/wedo_task' },
                 delegation: { '$ref' => '#/components/schemas/delegation_request' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let!(:pool) { create(:container_pool, project: project) }
        let!(:session) { create(:container_session, container_pool: pool) }
        let!(:task) { create(:wedo_task, project: project, dependency: 'AGENT_CAPABLE', status: 'pending') }
        let(:api_token) { create(:api_token, user: user, scopes: ['write:delegation']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:claim_request) { { task_id: task.task_id, session_id: session.session_id } }

        run_test!
      end

      response '409', 'Task already claimed' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'already_claimed' },
                 message: { type: :string }
               }

        # Test case for conflict scenario
        run_test! do |response|
          # This would require a more complex setup
        end
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/delegation/report_context' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Report context usage' do
      tags 'Delegation'
      description 'Reports context window usage and gets recommendations for handoff.'
      operationId 'reportContext'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :context_report, in: :body, schema: {
        type: :object,
        properties: {
          session_id: { type: :string },
          used_tokens: { type: :integer },
          max_tokens: { type: :integer }
        },
        required: %w[session_id used_tokens max_tokens]
      }

      response '200', 'Context reported' do
        schema type: :object,
               properties: {
                 updated: { type: :boolean },
                 session: { '$ref' => '#/components/schemas/container_session' },
                 action: { type: :string, enum: %w[continue handoff_recommended handoff_required] },
                 reason: { type: :string }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let!(:pool) { create(:container_pool, project: project) }
        let!(:session) { create(:container_session, container_pool: pool) }
        let(:api_token) { create(:api_token, user: user, scopes: ['write:delegation']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:context_report) { { session_id: session.session_id, used_tokens: 50000, max_tokens: 100000 } }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/delegation/handoff' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Record session handoff' do
      tags 'Delegation'
      description 'Records a handoff from one session to another when context is full.'
      operationId 'recordHandoff'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :handoff_data, in: :body, schema: {
        type: :object,
        properties: {
          old_session_id: { type: :string },
          new_session_id: { type: :string },
          container_id: { type: :string },
          summary: { type: :string, description: 'Handoff summary for context' }
        },
        required: %w[old_session_id new_session_id]
      }

      response '200', 'Handoff recorded' do
        schema type: :object,
               properties: {
                 handoff: { type: :boolean },
                 old_session: { '$ref' => '#/components/schemas/container_session' },
                 new_session: { '$ref' => '#/components/schemas/container_session' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let!(:pool) { create(:container_pool, project: project) }
        let!(:old_session) { create(:container_session, container_pool: pool) }
        let(:api_token) { create(:api_token, user: user, scopes: ['write:delegation']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:handoff_data) do
          {
            old_session_id: old_session.session_id,
            new_session_id: 'new-session-123',
            summary: 'Context at 85%, handing off remaining tasks'
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/delegation/next_task' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'Get next delegable task' do
      tags 'Delegation'
      description 'Returns the next AGENT_CAPABLE pending task that is not yet claimed.'
      operationId 'getNextTask'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Task found' do
        schema type: :object,
               properties: {
                 task: { '$ref' => '#/components/schemas/wedo_task', nullable: true },
                 message: { type: :string, nullable: true }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let!(:pool) { create(:container_pool, project: project) }
        let(:api_token) { create(:api_token, user: user, scopes: ['read:delegation']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end
    end
  end
end
