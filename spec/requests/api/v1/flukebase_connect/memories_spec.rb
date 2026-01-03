# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect Memories API', type: :request do
  # Shared setup for all tests
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  # Default token with read:memories scope for most tests
  let(:api_token) { create(:api_token, user: user, scopes: %w[read:memories read:projects]) }
  let(:Authorization) { "Bearer #{api_token.token}" }
  let(:project_id) { project.id }

  path '/api/v1/flukebase_connect/projects/{project_id}/memories' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'List project memories' do
      tags 'Memories'
      description 'Returns all memories (facts, conventions, gotchas, decisions) for a project.'
      operationId 'listMemories'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :type, in: :query, type: :string, required: false,
                enum: %w[fact convention gotcha decision],
                description: 'Filter by memory type'
      parameter name: :tag, in: :query, type: :string, required: false,
                description: 'Filter by tag'
      parameter name: :q, in: :query, type: :string, required: false,
                description: 'Search query'
      parameter name: :synced, in: :query, type: :string, required: false,
                enum: %w[true false],
                description: 'Filter by sync status'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'Memories retrieved successfully' do
        schema type: :object,
               properties: {
                 memories: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/memory' }
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
               },
               required: ['memories']

        run_test!
      end

      response '200', 'Memories filtered by type' do
        let(:type) { 'convention' }

        before do
          create(:project_memory, project: project, user: user, memory_type: 'fact')
          create(:project_memory, project: project, user: user, memory_type: 'convention')
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['memories']).to all(include('memory_type' => 'convention'))
        end
      end

      response '400', 'Invalid memory type' do
        let(:type) { 'invalid_type' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to include('Invalid memory type')
        end
      end

      response '401', 'Unauthorized - missing token' do
        let(:Authorization) { nil }
        run_test!
      end

      response '403', 'Forbidden - project not accessible' do
        let(:other_user) { create(:user) }
        let(:other_project) { create(:project, user: other_user) }
        let(:project_id) { other_project.id }

        run_test!
      end
    end

    post 'Create a memory' do
      tags 'Memories'
      description 'Creates a new memory for the project.'
      operationId 'createMemory'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :memory, in: :body, schema: {
        type: :object,
        properties: {
          content: { type: :string, example: 'Always use snake_case for Ruby methods' },
          memory_type: { type: :string, enum: %w[fact convention gotcha decision] },
          key: { type: :string, description: 'Unique key for conventions' },
          rationale: { type: :string, description: 'Reason for this memory' },
          tags: { type: :array, items: { type: :string }, example: %w[ruby style] },
          external_id: { type: :string, description: 'External ID for sync' }
        },
        required: %w[content memory_type]
      }

      response '201', 'Memory created successfully' do
        schema type: :object,
               properties: {
                 memory: { '$ref' => '#/components/schemas/memory' }
               },
               required: ['memory']

        let(:api_token) { create(:api_token, user: user, scopes: %w[write:memories read:projects]) }
        let(:memory) { { content: 'Test memory', memory_type: 'fact' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['memory']['content']).to eq('Test memory')
          expect(data['memory']['memory_type']).to eq('fact')
        end
      end

      response '201', 'Memory created with all fields' do
        let(:api_token) { create(:api_token, user: user, scopes: %w[write:memories read:projects]) }
        let(:memory) do
          {
            content: 'Use snake_case for Ruby methods',
            memory_type: 'convention',
            key: 'ruby_naming',
            rationale: 'Follows Ruby community standards',
            tags: %w[ruby style],
            external_id: 'mem_12345'
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['memory']['key']).to eq('ruby_naming')
          expect(data['memory']['tags']).to include('ruby')
        end
      end

      response '422', 'Validation error - missing content' do
        let(:api_token) { create(:api_token, user: user, scopes: %w[write:memories read:projects]) }
        let(:memory) { { memory_type: 'fact' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['errors']).to include("Content can't be blank")
        end
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { nil }
        let(:memory) { { content: 'Test', memory_type: 'fact' } }

        run_test!
      end

      response '403', 'Forbidden - missing write:memories scope' do
        let(:api_token) { create(:api_token, user: user, scopes: ['read:memories']) }
        let(:memory) { { content: 'Test', memory_type: 'fact' } }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/memories/{id}' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'
    parameter name: :id, in: :path, type: :integer, description: 'Memory ID'

    let(:existing_memory) { create(:project_memory, project: project, user: user) }
    let(:id) { existing_memory.id }

    get 'Get a specific memory' do
      tags 'Memories'
      description 'Returns details of a specific memory.'
      operationId 'getMemory'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Memory retrieved successfully' do
        schema type: :object,
               properties: {
                 memory: { '$ref' => '#/components/schemas/memory' }
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['memory']['id']).to eq(existing_memory.id)
        end
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end

      response '404', 'Memory not found' do
        let(:id) { 999999 }
        run_test!
      end
    end

    put 'Update a memory' do
      tags 'Memories'
      description 'Updates an existing memory.'
      operationId 'updateMemory'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :memory, in: :body, schema: {
        type: :object,
        properties: {
          content: { type: :string },
          memory_type: { type: :string, enum: %w[fact convention gotcha decision] },
          key: { type: :string },
          rationale: { type: :string },
          tags: { type: :array, items: { type: :string } }
        }
      }

      response '200', 'Memory updated successfully' do
        schema type: :object,
               properties: {
                 memory: { '$ref' => '#/components/schemas/memory' }
               }

        let(:api_token) { create(:api_token, user: user, scopes: ['write:memories']) }
        let(:memory) { { content: 'Updated content' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['memory']['content']).to eq('Updated content')
        end
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { nil }
        let(:memory) { { content: 'Updated' } }
        run_test!
      end

      response '403', 'Forbidden - missing write:memories scope' do
        let(:api_token) { create(:api_token, user: user, scopes: ['read:memories']) }
        let(:memory) { { content: 'Updated' } }
        run_test!
      end

      response '404', 'Memory not found' do
        let(:api_token) { create(:api_token, user: user, scopes: ['write:memories']) }
        let(:id) { 999999 }
        let(:memory) { { content: 'Updated' } }
        run_test!
      end
    end

    delete 'Delete a memory' do
      tags 'Memories'
      description 'Deletes a memory.'
      operationId 'deleteMemory'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Memory deleted successfully' do
        schema type: :object,
               properties: {
                 deleted: { type: :boolean }
               }

        let(:api_token) { create(:api_token, user: user, scopes: ['write:memories']) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['deleted']).to be true
          expect { existing_memory.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end

      response '403', 'Forbidden - missing write:memories scope' do
        let(:api_token) { create(:api_token, user: user, scopes: ['read:memories']) }
        run_test!
      end

      response '404', 'Memory not found' do
        let(:api_token) { create(:api_token, user: user, scopes: ['write:memories']) }
        let(:id) { 999999 }
        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/memories/conventions' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    get 'List conventions formatted for AI context' do
      tags 'Memories', 'AI'
      description 'Returns all conventions formatted for AI assistant context injection.'
      operationId 'listConventions'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Conventions retrieved successfully' do
        schema type: :object,
               properties: {
                 conventions: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       key: { type: :string },
                       value: { type: :string },
                       rationale: { type: :string },
                       tags: { type: :array, items: { type: :string } }
                     }
                   }
                 }
               }

        before do
          create(:project_memory, :convention, project: project, user: user,
                 key: 'naming', content: 'Use snake_case', rationale: 'Ruby standard')
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['conventions']).to be_an(Array)
          expect(data['conventions'].first['key']).to eq('naming')
        end
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/projects/{project_id}/memories/bulk_sync' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'

    post 'Bulk sync memories' do
      tags 'Memories', 'Sync'
      description 'Synchronizes multiple memories in a single request for bi-directional sync. Uses external_id for upsert logic.'
      operationId 'bulkSyncMemories'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :memories, in: :body, schema: {
        type: :object,
        properties: {
          memories: {
            type: :array,
            items: {
              type: :object,
              properties: {
                external_id: { type: :string, description: 'Required for sync - unique identifier' },
                content: { type: :string },
                memory_type: { type: :string, enum: %w[fact convention gotcha decision] },
                key: { type: :string },
                rationale: { type: :string },
                tags: { type: :array, items: { type: :string } }
              },
              required: %w[external_id content memory_type]
            }
          }
        },
        required: ['memories']
      }

      response '200', 'Sync completed - new memories created' do
        schema type: :object,
               properties: {
                 sync_results: {
                   type: :object,
                   properties: {
                     created: { type: :array },
                     updated: { type: :array },
                     errors: { type: :array }
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

        let(:api_token) { create(:api_token, user: user, scopes: ['write:memories']) }
        let(:memories) do
          {
            memories: [
              { external_id: 'mem_1', content: 'New memory', memory_type: 'fact' },
              { external_id: 'mem_2', content: 'Another memory', memory_type: 'convention', key: 'naming' }
            ]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['summary']['created']).to eq(2)
          expect(data['summary']['errors']).to eq(0)
        end
      end

      response '200', 'Sync completed - existing memories updated' do
        let(:api_token) { create(:api_token, user: user, scopes: ['write:memories']) }
        let!(:existing_memory) do
          create(:project_memory, project: project, user: user, external_id: 'mem_existing', content: 'Original')
        end
        let(:memories) do
          {
            memories: [
              { external_id: 'mem_existing', content: 'Updated content', memory_type: 'fact' }
            ]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['summary']['updated']).to eq(1)
          expect(data['summary']['created']).to eq(0)
          existing_memory.reload
          expect(existing_memory.content).to eq('Updated content')
        end
      end

      response '200', 'Sync with errors - missing external_id' do
        let(:api_token) { create(:api_token, user: user, scopes: ['write:memories']) }
        let(:memories) do
          {
            memories: [
              { content: 'No external_id', memory_type: 'fact' }
            ]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['summary']['errors']).to eq(1)
        end
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { nil }
        let(:memories) { { memories: [] } }
        run_test!
      end

      response '403', 'Forbidden - missing write:memories scope' do
        let(:api_token) { create(:api_token, user: user, scopes: ['read:memories']) }
        let(:memories) { { memories: [] } }
        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/memories/search' do
    get 'Search memories across projects' do
      tags 'Memories', 'Search'
      description 'Searches memories across all accessible projects.'
      operationId 'searchMemories'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :q, in: :query, type: :string, required: false,
                description: 'Search query string'
      parameter name: :type, in: :query, type: :string, required: false,
                enum: %w[fact convention gotcha decision],
                description: 'Filter by memory type'
      parameter name: :tag, in: :query, type: :string, required: false,
                description: 'Filter by tag'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'Search results' do
        schema type: :object,
               properties: {
                 memories: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/memory' }
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

        before do
          create(:project_memory, project: project, user: user, content: 'Ruby coding standard')
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('memories')
          expect(data).to have_key('meta')
        end
      end

      response '200', 'Search with query filter' do
        let(:q) { 'ruby' }

        before do
          create(:project_memory, project: project, user: user, content: 'Ruby coding standard')
          create(:project_memory, project: project, user: user, content: 'Python style guide')
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['memories'].map { |m| m['content'] }).to all(match(/ruby/i))
        end
      end

      response '200', 'Search with type filter' do
        let(:type) { 'convention' }

        before do
          create(:project_memory, project: project, user: user, memory_type: 'fact')
          create(:project_memory, project: project, user: user, memory_type: 'convention')
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['memories']).to all(include('memory_type' => 'convention'))
        end
      end

      response '400', 'Invalid memory type' do
        let(:type) { 'invalid' }
        run_test!
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/batch/memories' do
    get 'Batch pull memories from multiple projects' do
      tags 'Memories', 'Batch'
      description 'Pulls memories from multiple projects at once for efficient local sync.'
      operationId 'batchPullMemories'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: 'project_ids[]', in: :query, type: :array,
                items: { type: :integer }, required: false,
                description: 'Array of project IDs (or use all=true)'
      parameter name: :type, in: :query, type: :string, required: false,
                enum: %w[fact convention gotcha decision],
                description: 'Filter by memory type'
      parameter name: :since, in: :query, type: :string, required: false,
                description: 'ISO8601 timestamp for incremental sync'

      response '200', 'Batch pull successful with all projects' do
        schema type: :object,
               properties: {
                 projects: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       project_id: { type: :integer },
                       project_name: { type: :string },
                       memories: { type: :array },
                       memories_count: { type: :integer }
                     }
                   }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     project_count: { type: :integer },
                     total_memories: { type: :integer }
                   }
                 }
               }

        before do
          create(:project_memory, project: project, user: user, content: 'Memory 1')
          create(:project_memory, project: project, user: user, content: 'Memory 2')
        end

        # Use direct request with all=true parameter
        it 'returns a 200 response' do
          auth_header = "Bearer #{api_token.token}"
          get '/api/v1/flukebase_connect/batch/memories',
              params: { all: true },
              headers: { 'Authorization' => auth_header }
          expect(response).to have_http_status(:ok)
          data = JSON.parse(response.body)
          expect(data['projects']).to be_an(Array)
          expect(data['meta']['project_count']).to be >= 1
        end
      end

      response '200', 'Batch pull with specific project IDs' do
        let(:'project_ids[]') { [project.id] }

        before do
          create(:project_memory, project: project, user: user, content: 'Memory 1')
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['projects'].length).to eq(1)
          expect(data['projects'].first['project_id']).to eq(project.id)
        end
      end

      response '200', 'Batch pull with type filter' do
        before do
          create(:project_memory, project: project, user: user, memory_type: 'fact')
          create(:project_memory, project: project, user: user, memory_type: 'convention')
        end

        it 'returns only conventions' do
          auth_header = "Bearer #{api_token.token}"
          get '/api/v1/flukebase_connect/batch/memories',
              params: { all: true, type: 'convention' },
              headers: { 'Authorization' => auth_header }
          expect(response).to have_http_status(:ok)
          data = JSON.parse(response.body)
          memories_list = data['projects'].flat_map { |p| p['memories'] }
          memory_types = memories_list.map { |m| m['memory_type'] }.uniq
          expect(memory_types).to eq(['convention'])
        end
      end

      response '200', 'Batch pull with since filter for incremental sync' do
        before do
          create(:project_memory, project: project, user: user, content: 'Recent', updated_at: 30.minutes.ago)
        end

        it 'returns memories updated since timestamp' do
          auth_header = "Bearer #{api_token.token}"
          get '/api/v1/flukebase_connect/batch/memories',
              params: { all: true, since: 1.hour.ago.iso8601 },
              headers: { 'Authorization' => auth_header }
          expect(response).to have_http_status(:ok)
        end
      end

      response '200', 'Empty result when no projects specified' do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['projects']).to eq([])
          expect(data['meta']['count']).to eq(0)
        end
      end

      response '400', 'Invalid memory type' do
        it 'returns error for invalid type' do
          auth_header = "Bearer #{api_token.token}"
          get '/api/v1/flukebase_connect/batch/memories',
              params: { all: true, type: 'invalid' },
              headers: { 'Authorization' => auth_header }
          expect(response).to have_http_status(:bad_request)
        end
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
