# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect WeDo Tasks API', type: :request do
  path '/api/v1/flukebase_connect/projects/{project_id}/wedo_tasks' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'List WeDo tasks' do
      tags 'WeDo Tasks'
      description 'Returns WeDo tasks for the Team Board. Supports incremental sync via since_version parameter.'
      operationId 'listWedoTasks'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :status, in: :query, type: :string, required: false,
                enum: %w[pending in_progress completed blocked],
                description: 'Filter by status'
      parameter name: :scope, in: :query, type: :string, required: false,
                description: 'Filter by scope (default: global)'
      parameter name: :assignee_id, in: :query, type: :integer, required: false,
                description: 'Filter by assignee'
      parameter name: :root_only, in: :query, type: :boolean, required: false,
                description: 'Only return tasks without parent'
      parameter name: :since_version, in: :query, type: :integer, required: false,
                description: 'Only return tasks with version > N (for incremental sync)'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'Tasks retrieved' do
        schema type: :object,
               properties: {
                 tasks: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/wedo_task' }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     total: { type: :integer },
                     page: { type: :integer },
                     per_page: { type: :integer },
                     pages: { type: :integer },
                     max_version: { type: :integer, description: 'Highest version for sync' }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[read:tasks read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }

        run_test!
      end
    end

    post 'Create WeDo task' do
      tags 'WeDo Tasks'
      description 'Creates a new WeDo task from flukebase_connect.'
      operationId 'createWedoTask'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          task: {
            type: :object,
            properties: {
              task_id: { type: :string, example: 'FEAT-001', description: 'Unique task identifier' },
              description: { type: :string },
              status: { type: :string, enum: %w[pending in_progress completed blocked] },
              dependency: { type: :string, enum: %w[USER_REQUIRED AGENT_CAPABLE], default: 'AGENT_CAPABLE' },
              scope: { type: :string, default: 'global' },
              priority: { type: :integer },
              blocked_by: { type: :array, items: { type: :string } },
              tags: { type: :array, items: { type: :string } },
              artifact_path: { type: :string, nullable: true },
              remote_url: { type: :string, nullable: true },
              parent_task_id: { type: :string, nullable: true },
              agent_id: { type: :string, nullable: true }
            },
            required: %w[task_id description]
          }
        },
        required: ['task']
      }

      response '201', 'Task created' do
        schema type: :object,
               properties: {
                 task: { '$ref' => '#/components/schemas/wedo_task' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:tasks read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:body_params) { { task: { task_id: 'TEST-001', description: 'Test task' } } }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/wedo_tasks/{id}' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'
    parameter name: :id, in: :path, type: :string, description: 'Task ID or database ID'

    get 'Get task details' do
      tags 'WeDo Tasks'
      description 'Returns detailed information about a WeDo task including subtasks.'
      operationId 'getWedoTask'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Task retrieved' do
        schema type: :object,
               properties: {
                 task: { '$ref' => '#/components/schemas/wedo_task' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:task_record) { create(:wedo_task, project:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[read:tasks read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { task_record.task_id }

        run_test!
      end
    end

    put 'Update task' do
      tags 'WeDo Tasks'
      description 'Updates a WeDo task with optimistic locking support.'
      operationId 'updateWedoTask'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          task: {
            type: :object,
            properties: {
              description: { type: :string },
              status: { type: :string, enum: %w[pending in_progress completed blocked] },
              version: { type: :integer, description: 'Client version for conflict detection' },
              synthesis_note: { type: :string, description: 'Note to append to synthesis report' },
              agent_id: { type: :string }
            }
          }
        }
      }

      response '200', 'Task updated' do
        schema type: :object,
               properties: {
                 task: { '$ref' => '#/components/schemas/wedo_task' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:task_record) { create(:wedo_task, project:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:tasks read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { task_record.task_id }
        let(:body_params) { { task: { status: 'in_progress' } } }

        run_test!
      end

      response '409', 'Conflict - task modified' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'conflict' },
                 message: { type: :string },
                 server_task: { '$ref' => '#/components/schemas/wedo_task' }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:task_record) { create(:wedo_task, project:, version: 5) }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:tasks read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { task_record.task_id }
        let(:body_params) { { task: { status: 'completed', version: 1 } } }

        run_test!
      end
    end

    delete 'Delete task' do
      tags 'WeDo Tasks'
      description 'Deletes a WeDo task.'
      operationId 'deleteWedoTask'
      security [bearer_auth: []]

      response '200', 'Task deleted' do
        schema type: :object,
               properties: {
                 deleted: { type: :boolean },
                 task_id: { type: :string }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:task_record) { create(:wedo_task, project:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:tasks read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:id) { task_record.task_id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/wedo_tasks/bulk_sync' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Bulk sync tasks' do
      tags 'WeDo Tasks', 'Sync'
      description 'Synchronizes multiple tasks with conflict detection and resolution.'
      operationId 'bulkSyncWedoTasks'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          tasks: {
            type: :array,
            items: {
              type: :object,
              properties: {
                external_id: { type: :string },
                task_id: { type: :string },
                description: { type: :string },
                status: { type: :string },
                version: { type: :integer },
                agent_id: { type: :string }
              }
            }
          }
        },
        required: ['tasks']
      }

      response '200', 'Sync completed' do
        schema type: :object,
               properties: {
                 sync_results: {
                   type: :object,
                   properties: {
                     created: { type: :array, items: { '$ref' => '#/components/schemas/wedo_task' } },
                     updated: { type: :array, items: { '$ref' => '#/components/schemas/wedo_task' } },
                     conflicts: { type: :array, items: { '$ref' => '#/components/schemas/wedo_task' } },
                     errors: { type: :array, items: { type: :object } }
                   }
                 },
                 summary: {
                   type: :object,
                   properties: {
                     created: { type: :integer },
                     updated: { type: :integer },
                     conflicts: { type: :integer },
                     errors: { type: :integer }
                   }
                 },
                 max_version: { type: :integer }
               }

        let(:user) { create(:user) }
        let(:project) { create(:project, user:) }
        let(:api_token) { create(:api_token, user:, scopes: %w[write:tasks read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project_id) { project.id }
        let(:body_params) do
          { tasks: [{ task_id: 'SYNC-001', description: 'Synced task' }] }
        end

        run_test!
      end
    end
  end
end
