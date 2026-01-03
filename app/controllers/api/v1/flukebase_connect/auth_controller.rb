# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      class AuthController < BaseController
        # GET /api/v1/connect/auth/validate
        # Validate the API token and return token info
        def validate
          render_success({
            valid: true,
            token: {
              prefix: current_api_token.prefix,
              name: current_api_token.name,
              scopes: current_api_token.scopes,
              expires_at: current_api_token.expires_at&.iso8601
            }
          })
        end

        # GET /api/v1/connect/auth/me
        # Get current user information
        def me
          render_success({
            user: {
              id: current_user.id,
              email: current_user.email,
              name: current_user.full_name,
              project_count: current_user.accessible_projects.count
            }
          })
        end
      end
    end
  end
end
