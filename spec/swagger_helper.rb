# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'FlukeBase Connect API',
        version: 'v1',
        description: 'API for flukebase_connect MCP server integration. Provides authentication, ' \
                     'project management, environment variables, memories, and AI productivity metrics.',
        contact: {
          name: 'FlukeBase Support',
          email: 'support@flukebase.com'
        }
      },
      paths: {},
      servers: [
        {
          url: 'https://flukebase.com',
          description: 'Production server'
        },
        {
          url: 'http://localhost:3006',
          description: 'Development server'
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'API Token',
            description: 'FlukeBase API token (starts with fbk_)'
          }
        },
        schemas: {
          error: {
            type: :object,
            properties: {
              error: { type: :string, description: 'Error message' }
            },
            required: ['error']
          },
          project: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string, nullable: true },
              repository_url: { type: :string, nullable: true },
              stage: { type: :string, enum: %w[idea prototype mvp growth mature] },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id name stage]
          },
          memory: {
            type: :object,
            properties: {
              id: { type: :integer },
              content: { type: :string },
              memory_type: { type: :string, enum: %w[fact convention gotcha decision] },
              tags: { type: :array, items: { type: :string } },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id content memory_type]
          },
          environment_variable: {
            type: :object,
            properties: {
              key: { type: :string },
              value: { type: :string },
              description: { type: :string, nullable: true },
              is_secret: { type: :boolean },
              is_required: { type: :boolean },
              example_value: { type: :string, nullable: true },
              environment: { type: :string, enum: %w[development staging production] }
            },
            required: %w[key value environment]
          },
          webhook: {
            type: :object,
            properties: {
              id: { type: :integer },
              callback_url: { type: :string, format: :uri },
              events: { type: :array, items: { type: :string } },
              active: { type: :boolean },
              healthy: { type: :boolean },
              failure_count: { type: :integer },
              secret: { type: :string, nullable: true, description: 'Only included for show' },
              last_success_at: { type: :string, format: 'date-time', nullable: true },
              last_failure_at: { type: :string, format: 'date-time', nullable: true },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id callback_url events active]
          },
          productivity_metric: {
            type: :object,
            properties: {
              id: { type: :integer },
              project_id: { type: :integer },
              user_id: { type: :integer },
              metric_type: { type: :string, enum: %w[time_saved code_contribution task_velocity token_efficiency] },
              period_type: { type: :string, enum: %w[session daily weekly monthly] },
              period_start: { type: :string, format: 'date-time', nullable: true },
              period_end: { type: :string, format: 'date-time', nullable: true },
              metric_data: { type: :object },
              external_id: { type: :string, nullable: true },
              synced_at: { type: :string, format: 'date-time', nullable: true },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id metric_type period_type metric_data]
          },
          wedo_task: {
            type: :object,
            properties: {
              id: { type: :integer },
              task_id: { type: :string },
              description: { type: :string },
              status: { type: :string, enum: %w[pending in_progress completed blocked] },
              dependency: { type: :string, enum: %w[USER_REQUIRED AGENT_CAPABLE] },
              scope: { type: :string },
              priority: { type: :string, enum: %w[low normal high urgent] },
              version: { type: :integer },
              blocked_by: { type: :array, items: { type: :string } },
              tags: { type: :array, items: { type: :string } },
              artifact_path: { type: :string, nullable: true },
              remote_url: { type: :string, nullable: true },
              synthesis_report: { type: :string, nullable: true },
              external_id: { type: :string, nullable: true },
              parent_task_id: { type: :string, nullable: true },
              assignee_id: { type: :integer, nullable: true },
              due_date: { type: :string, format: :date, nullable: true },
              completed_at: { type: :string, format: 'date-time', nullable: true },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id task_id description status]
          },
          agent_session: {
            type: :object,
            properties: {
              id: { type: :integer },
              agent_id: { type: :string },
              persona_name: { type: :string, nullable: true },
              agent_type: { type: :string, nullable: true },
              status: { type: :string, enum: %w[active idle disconnected] },
              capabilities: { type: :array, items: { type: :string } },
              client_version: { type: :string, nullable: true },
              tokens_used: { type: :integer },
              tools_executed: { type: :integer },
              last_heartbeat_at: { type: :string, format: 'date-time', nullable: true },
              connected_at: { type: :string, format: 'date-time' },
              disconnected_at: { type: :string, format: 'date-time', nullable: true },
              metadata: { type: :object }
            },
            required: %w[id agent_id status]
          },
          ai_conversation_log: {
            type: :object,
            properties: {
              id: { type: :integer },
              provider: { type: :string },
              model: { type: :string },
              session_id: { type: :string, nullable: true },
              external_id: { type: :string, nullable: true },
              message_index: { type: :integer },
              role: { type: :string, enum: %w[user assistant system tool] },
              content: { type: :string },
              input_tokens: { type: :integer, nullable: true },
              output_tokens: { type: :integer, nullable: true },
              duration_ms: { type: :integer, nullable: true },
              metadata: { type: :object },
              exchanged_at: { type: :string, format: 'date-time' },
              created_at: { type: :string, format: 'date-time' }
            },
            required: %w[id provider role content]
          },
          container_pool: {
            type: :object,
            properties: {
              id: { type: :integer },
              project_id: { type: :integer },
              warm_pool_size: { type: :integer },
              max_pool_size: { type: :integer },
              context_threshold_percent: { type: :integer },
              auto_delegate_enabled: { type: :boolean },
              skip_user_required: { type: :boolean },
              active_session_count: { type: :integer },
              idle_session_count: { type: :integer },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id project_id]
          },
          container_session: {
            type: :object,
            properties: {
              id: { type: :integer },
              session_id: { type: :string },
              container_id: { type: :string, nullable: true },
              status: { type: :string, enum: %w[starting active idle retired] },
              context_percent: { type: :integer },
              tasks_completed: { type: :integer },
              handoff_summary: { type: :string, nullable: true },
              last_activity_at: { type: :string, format: 'date-time', nullable: true },
              created_at: { type: :string, format: 'date-time' }
            },
            required: %w[id session_id status]
          },
          delegation_request: {
            type: :object,
            properties: {
              id: { type: :integer },
              wedo_task_id: { type: :integer },
              container_session_id: { type: :integer },
              status: { type: :string, enum: %w[claimed executing completed failed] },
              claimed_at: { type: :string, format: 'date-time' },
              started_at: { type: :string, format: 'date-time', nullable: true },
              completed_at: { type: :string, format: 'date-time', nullable: true },
              result: { type: :object, nullable: true }
            },
            required: %w[id wedo_task_id container_session_id status]
          }
        }
      },
      security: [
        { bearer_auth: [] }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  config.openapi_format = :yaml
end
