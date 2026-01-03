# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect Docs API', type: :request do
  let(:user) { create(:user) }
  let(:raw_token) { "fbk_#{SecureRandom.urlsafe_base64(32)}" }
  let(:api_token) { create(:api_token, user:, raw_token:) }

  path '/api/v1/flukebase_connect/docs/llms.txt' do
    get 'Get llms.txt navigation file' do
      tags 'Documentation'
      description 'Returns AI-friendly documentation navigation following the llms.txt specification. ' \
                  'Provides links to key documentation sections optimized for LLM context windows.'
      operationId 'getLlmsTxt'
      produces 'text/plain'
      security [bearer_auth: []]

      response '200', 'Navigation file retrieved' do
        schema type: :string,
               description: 'Markdown-formatted navigation file following llms.txt spec'

        let(:Authorization) { "Bearer #{raw_token}" }

        before { api_token } # Ensure token is created

        run_test! do |response|
          expect(response.body).to include('# FlukeBase')
          expect(response.body).to include('## Quick Start')
          expect(response.body).to include('## API Reference')
        end
      end

      response '401', 'Unauthorized - missing or invalid token' do
        schema '$ref' => '#/components/schemas/error'

        let(:Authorization) { 'Bearer invalid_token' }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/docs/llms-full.txt' do
    get 'Get llms-full.txt complete documentation' do
      tags 'Documentation'
      description 'Returns comprehensive AI-friendly documentation in a single file. ' \
                  'Includes complete API reference, MCP tools mapping, commands, and domain models.'
      operationId 'getLlmsFullTxt'
      produces 'text/plain'
      security [bearer_auth: []]

      response '200', 'Full documentation retrieved' do
        schema type: :string,
               description: 'Complete markdown documentation optimized for LLM consumption'

        let(:Authorization) { "Bearer #{raw_token}" }

        before { api_token } # Ensure token is created

        run_test! do |response|
          expect(response.body).to include('# FlukeBase')
          expect(response.body).to include('## Technology Stack')
          expect(response.body).to include('## API Reference')
          expect(response.body).to include('## MCP Tools Quick Reference')
        end
      end

      response '401', 'Unauthorized - missing or invalid token' do
        schema '$ref' => '#/components/schemas/error'

        let(:Authorization) { 'Bearer invalid_token' }

        run_test!
      end
    end
  end
end
