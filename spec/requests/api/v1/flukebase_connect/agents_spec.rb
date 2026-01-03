# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect Agents API', type: :request do
  path '/api/v1/flukebase_connect/projects/{project_id}/agents' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'List agent sessions' do
      tags 'Agents'
      description 'Returns all agent sessions for multi-agent coordination on the Team Board.'
      operationId 'listAgents'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :status, in: :query, type: :string, required: false,
                enum: %w[active idle disconnected],
                description: 'Filter by status'
      parameter name: :agent_type, in: :query, type: :string, required: false,
                description: 'Filter by agent type (e.g., claude_code)'
      parameter name: :connected_only, in: :query, type: :boolean, required: false,
                description: 'Only return active/idle agents'
      parameter name: :with_persona, in: :query, type: :boolean, required: false,
                description: 'Only return named personas (ZION, KORE, etc.)'
      parameter name: :refresh_status, in: :query, type: :boolean, required: false,
                description: 'Mark stale agents as idle before returning'

      response '200', 'Agents retrieved' do
        schema type: :object,
               properties: {
                 agents: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/agent_session' }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     total: { type: :integer },
                     page: { type: :integer },
                     per_page: { type: :integer },
                     active_count: { type: :integer },
                     connected_count: { type: :integer }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[read:agents read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/agents/register' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Register agent session' do
      tags 'Agents'
      description 'Registers or updates an agent session for multi-agent coordination.'
      operationId 'registerAgent'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :agent, in: :body, schema: {
        type: :object,
        properties: {
          agent_id: { type: :string, example: 'session-abc123' },
          persona_name: { type: :string, example: 'ZION', nullable: true },
          agent_type: { type: :string, example: 'claude_code' },
          capabilities: { type: :array, items: { type: :string }, example: %w[memory wedo] },
          client_version: { type: :string, example: '1.2.3' },
          metadata: { type: :object }
        },
        required: ['agent_id']
      }

      response '201', 'Agent registered (new)' do
        schema type: :object,
               properties: {
                 agent: { '$ref' => '#/components/schemas/agent_session' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:agents read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:agent) { { agent_id: 'test-session-123', agent_type: 'claude_code' } }

        run_test!
      end

      response '200', 'Agent updated (existing)' do
        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:existing_agent) { create(:agent_session, project:, agent_id: 'existing-123') }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:agents read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:agent) { { agent_id: 'existing-123', persona_name: 'ZION' } }

        before { existing_agent }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/agents/{id}' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'
    parameter name: :id, in: :path, type: :string, description: 'Agent ID or database ID'

    get 'Get agent session' do
      tags 'Agents'
      description 'Returns detailed information about an agent session.'
      operationId 'getAgent'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Agent retrieved' do
        schema type: :object,
               properties: {
                 agent: { '$ref' => '#/components/schemas/agent_session' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:agent_record) { create(:agent_session, project:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[read:agents read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { agent_record.agent_id }

        run_test!
      end
    end

    put 'Update agent session' do
      tags 'Agents'
      description 'Updates agent session metadata.'
      operationId 'updateAgent'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :agent, in: :body, schema: {
        type: :object,
        properties: {
          persona_name: { type: :string },
          agent_type: { type: :string },
          status: { type: :string, enum: %w[active idle disconnected] },
          capabilities: { type: :array, items: { type: :string } },
          metadata: { type: :object }
        }
      }

      response '200', 'Agent updated' do
        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:agent_record) { create(:agent_session, project:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:agents read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { agent_record.agent_id }
        let(:agent) { { persona_name: 'KORE' } }

        run_test!
      end
    end

    delete 'Disconnect agent' do
      tags 'Agents'
      description 'Disconnects an agent session. Use hard_delete=true to permanently remove.'
      operationId 'disconnectAgent'
      security [bearer_auth: []]

      parameter name: :hard_delete, in: :query, type: :boolean, required: false,
                description: 'Permanently delete instead of marking disconnected'

      response '200', 'Agent disconnected' do
        schema type: :object,
               properties: {
                 agent: { '$ref' => '#/components/schemas/agent_session' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:agent_record) { create(:agent_session, project:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:agents read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { agent_record.agent_id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/agents/{id}/heartbeat' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'
    parameter name: :id, in: :path, type: :string, description: 'Agent ID'

    post 'Send heartbeat' do
      tags 'Agents'
      description 'Updates agent heartbeat to indicate the session is still active.'
      operationId 'agentHeartbeat'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :heartbeat_data, in: :body, schema: {
        type: :object,
        properties: {
          tokens_used: { type: :integer, description: 'Tokens used since last heartbeat' },
          tools_executed: { type: :integer, description: 'Tools executed since last heartbeat' },
          metadata: { type: :object }
        }
      }

      response '200', 'Heartbeat recorded' do
        schema type: :object,
               properties: {
                 agent: { '$ref' => '#/components/schemas/agent_session' },
                 server_time: { type: :string, format: 'date-time' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:agent_record) { create(:agent_session, project:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:agents read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { agent_record.agent_id }
        let(:heartbeat_data) { { tokens_used: 100 } }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/agents/whoami' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'Get current agent' do
      tags 'Agents'
      description 'Returns the agent session for the current X-Agent-ID header or agent_id parameter.'
      operationId 'agentWhoami'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: 'X-Agent-ID', in: :header, type: :string, required: false,
                description: 'Agent ID header'
      parameter name: :agent_id, in: :query, type: :string, required: false,
                description: 'Agent ID parameter (alternative to header)'

      response '200', 'Agent found' do
        schema type: :object,
               properties: {
                 agent: { '$ref' => '#/components/schemas/agent_session' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:agent_record) { create(:agent_session, project:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[read:agents read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:agent_id) { agent_record.agent_id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/agents/cleanup' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Cleanup stale sessions' do
      tags 'Agents'
      description 'Marks stale agents as idle and optionally disconnects/deletes old sessions.'
      operationId 'cleanupAgents'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :cleanup_options, in: :body, schema: {
        type: :object,
        properties: {
          disconnect_stale: { type: :boolean, description: 'Disconnect long-idle sessions' },
          delete_disconnected: { type: :boolean, description: 'Hard delete old disconnected sessions' },
          older_than_hours: { type: :integer, description: 'Age threshold for deletion (default: 24)' }
        }
      }

      response '200', 'Cleanup completed' do
        schema type: :object,
               properties: {
                 cleanup_results: {
                   type: :object,
                   properties: {
                     marked_idle: { type: :integer },
                     disconnected: { type: :integer },
                     deleted: { type: :integer }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:agents read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:cleanup_options) { { disconnect_stale: true } }

        run_test!
      end
    end
  end
end
