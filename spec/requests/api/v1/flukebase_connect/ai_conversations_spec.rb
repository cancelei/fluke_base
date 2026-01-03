# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect AI Conversations API', type: :request do
  path '/api/v1/flukebase_connect/projects/{project_id}/ai_conversations' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'List AI conversation logs' do
      tags 'AI Conversations'
      description 'Returns AI conversation logs for the Unified Logs dashboard.'
      operationId 'listAiConversations'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :provider, in: :query, type: :string, required: false,
                description: 'Filter by AI provider (claude, openai, etc.)'
      parameter name: :session_id, in: :query, type: :string, required: false,
                description: 'Filter by session ID'
      parameter name: :role, in: :query, type: :string, required: false,
                enum: %w[user assistant system tool],
                description: 'Filter by message role'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum results (default: 100)'

      response '200', 'Logs retrieved' do
        schema type: :object,
               properties: {
                 logs: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/ai_conversation_log' }
                 },
                 count: { type: :integer },
                 project_id: { type: :integer }
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

  path '/api/v1/flukebase_connect/projects/{project_id}/ai_conversations/{id}' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'
    parameter name: :id, in: :path, type: :integer, description: 'Log ID'

    get 'Get conversation log details' do
      tags 'AI Conversations'
      description 'Returns detailed information about a specific AI conversation log entry.'
      operationId 'getAiConversation'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Log retrieved' do
        schema type: :object,
               properties: {
                 log: { '$ref' => '#/components/schemas/ai_conversation_log' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:log_record) { create(:ai_conversation_log, project: project, user: user) }
        let(:api_token) { create(:api_token, user: user, scopes: ['read:metrics']) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { log_record.id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/ai_conversations/bulk_sync' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Bulk sync AI conversation logs' do
      tags 'AI Conversations', 'Sync'
      description 'Synchronizes AI conversation logs from flukebase_connect. Broadcasts to UnifiedLogsChannel for real-time updates.'
      operationId 'bulkSyncAiConversations'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :sync_data, in: :body, schema: {
        type: :object,
        properties: {
          logs: {
            type: :array,
            items: {
              type: :object,
              properties: {
                external_id: { type: :string, description: 'Unique identifier from client' },
                provider: { type: :string, example: 'claude' },
                model: { type: :string, example: 'claude-3-opus' },
                session_id: { type: :string },
                message_index: { type: :integer },
                role: { type: :string, enum: %w[user assistant system tool] },
                content: { type: :string },
                input_tokens: { type: :integer, nullable: true },
                output_tokens: { type: :integer, nullable: true },
                duration_ms: { type: :integer, nullable: true },
                metadata: { type: :object },
                exchanged_at: { type: :string, format: 'date-time' }
              },
              required: %w[provider role content]
            }
          },
          broadcast: { type: :boolean, default: true, description: 'Broadcast to UnifiedLogsChannel' }
        },
        required: ['logs']
      }

      response '200', 'Sync completed' do
        schema type: :object,
               properties: {
                 synced: { type: :integer },
                 created: { type: :integer },
                 updated: { type: :integer },
                 errors: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       index: { type: :integer },
                       external_id: { type: :string },
                       error: { type: :string }
                     }
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
            logs: [
              {
                external_id: 'log-123',
                provider: 'claude',
                model: 'claude-3-opus',
                role: 'user',
                content: 'Hello!'
              }
            ]
          }
        end

        run_test!
      end
    end
  end
end
