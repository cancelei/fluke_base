# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'FlukeBase Connect Authentication API', type: :request do
  path '/api/v1/flukebase_connect/auth/validate' do
    get 'Validate API token' do
      tags 'Authentication'
      description 'Validates the provided API token and returns authentication status. ' \
                  'Used by flukebase_connect to verify token validity before making API calls.'
      operationId 'validateToken'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'Token is valid' do
        schema type: :object,
               properties: {
                 valid: { type: :boolean, example: true },
                 user_id: { type: :integer, example: 1 },
                 scopes: {
                   type: :array,
                   items: { type: :string },
                   example: %w[read:projects write:projects read:memories]
                 }
               },
               required: %w[valid user_id scopes]

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user:) }
        let(:Authorization) { "Bearer #{api_token.token}" }

        run_test!
      end

      response '401', 'Invalid or missing token' do
        schema '$ref' => '#/components/schemas/error'

        let(:Authorization) { 'Bearer invalid_token' }

        run_test!
      end
    end
  end

  path '/api/v1/flukebase_connect/auth/me' do
    get 'Get current user info' do
      tags 'Authentication'
      description 'Returns information about the authenticated user based on the API token. ' \
                  'Includes user details and accessible projects.'
      operationId 'getCurrentUser'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'User information retrieved' do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 email: { type: :string, format: :email },
                 name: { type: :string },
                 projects: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/project' }
                 }
               },
               required: %w[id email]

        let(:user) { create(:user) }
        let(:api_token) { create(:api_token, user:) }
        let(:Authorization) { "Bearer #{api_token.token}" }

        run_test!
      end

      response '401', 'Unauthorized' do
        schema '$ref' => '#/components/schemas/error'

        let(:Authorization) { nil }

        run_test!
      end
    end
  end
end
