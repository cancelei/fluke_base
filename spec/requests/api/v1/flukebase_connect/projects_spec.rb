# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect Projects API', type: :request do
  path '/api/v1/flukebase_connect/projects' do
    get 'List accessible projects' do
      tags 'Projects'
      description 'Returns all projects the authenticated user has access to. ' \
                  'Includes projects the user owns and projects they collaborate on.'
      operationId 'listProjects'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Projects retrieved successfully' do
        schema type: :object,
               properties: {
                 projects: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/project' }
                 }
               },
               required: ['projects']

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user: user) }
        let(:Authorization) { "Bearer #{api_token.token}" }

        run_test!
      end

      response '401', 'Unauthorized' do
        schema '$ref' => '#/components/schemas/error'
        let(:Authorization) { nil }
        run_test!
      end
    end

    post 'Create a new project' do
      tags 'Projects'
      description 'Creates a new project for the authenticated user.'
      operationId 'createProject'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :project, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'My New Project' },
          description: { type: :string, example: 'A description of the project' },
          repository_url: { type: :string, example: 'https://github.com/user/repo' },
          stage: { type: :string, enum: %w[idea prototype mvp growth mature], example: 'prototype' }
        },
        required: ['name']
      }

      response '201', 'Project created successfully' do
        schema type: :object,
               properties: {
                 project: { '$ref' => '#/components/schemas/project' }
               },
               required: ['project']

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user: user, scopes: %w[write:projects read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project) { { name: 'Test Project', description: 'A test project', stage: 'prototype' } }

        run_test!
      end

      response '422', 'Validation error' do
        schema type: :object,
               properties: {
                 errors: {
                   type: :object,
                   additionalProperties: {
                     type: :array,
                     items: { type: :string }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user: user, scopes: %w[write:projects read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:project) { { name: '' } }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Project ID'

    get 'Get project details' do
      tags 'Projects'
      description 'Returns detailed information about a specific project.'
      operationId 'getProject'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Project retrieved successfully' do
        schema type: :object,
               properties: {
                 project: { '$ref' => '#/components/schemas/project' }
               },
               required: ['project']

        let(:user) { create(:user) }
        let(:project_record) { create(:project, user: user) }
        let(:api_token) { create(:api_token, user: user, scopes: %w[read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:id) { project_record.id }

        run_test!
      end

      response '404', 'Project not found' do
        schema '$ref' => '#/components/schemas/error'

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user: user, scopes: %w[read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:id) { 999_999 }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{id}/context' do
    parameter name: :id, in: :path, type: :integer, description: 'Project ID'

    get 'Get project context for AI agent' do
      tags 'Projects'
      description 'Returns the project context including conventions, gotchas, and recent decisions. ' \
                  'This endpoint is used by flukebase_connect to provide context to AI agents.'
      operationId 'getProjectContext'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Context retrieved successfully' do
        schema type: :object,
               properties: {
                 context: { type: :object }
               },
               required: %w[context]

        let(:user) { create(:user) }
        let(:project_record) { create(:project, user: user) }
        let(:api_token) { create(:api_token, user: user, scopes: %w[read:projects read:context]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:id) { project_record.id }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/find' do
    get 'Find project by repository URL' do
      tags 'Projects'
      description 'Looks up a project by its Git repository URL. ' \
                  'Used by flukebase_connect to auto-detect the project based on the current working directory.'
      operationId 'findProjectByRepository'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :repository_url, in: :query, type: :string,
                description: 'Git repository URL to search for',
                example: 'https://github.com/user/repo'

      response '200', 'Project found' do
        schema type: :object,
               properties: {
                 project: { '$ref' => '#/components/schemas/project' }
               },
               required: ['project']

        let(:user) { create(:user) }
        let(:project_record) { create(:project, user: user, repository_url: 'https://github.com/test/repo') }
        let(:api_token) { create(:api_token, user: user, scopes: %w[read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:repository_url) { 'https://github.com/test/repo' }

        before { project_record }

        run_test!
      end

      response '200', 'Project not found (returns null project)' do
        schema type: :object,
               properties: {
                 project: { type: :object, nullable: true }
               }

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user: user, scopes: %w[read:projects]) }
        let(:Authorization) { "Bearer #{api_token.token}" }
        let(:repository_url) { 'https://github.com/nonexistent/repo' }

        run_test!
      end
    end
  end

  # Note: Using direct it block to avoid conflict with RSpec's 'all' matcher
  describe 'GET /api/v1/flukebase_connect/batch/context' do
    it 'returns batch context for all accessible projects' do
      user = create(:user)
      api_token = create(:api_token, user: user, scopes: %w[read:projects read:context])

      get '/api/v1/flukebase_connect/batch/context',
          params: { all: true },
          headers: { 'Authorization' => "Bearer #{api_token.token}" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key('contexts')
      expect(json).to have_key('meta')
    end
  end
end
