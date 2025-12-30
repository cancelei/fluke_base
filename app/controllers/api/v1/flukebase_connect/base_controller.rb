# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      class BaseController < ActionController::API
        include ActionController::HttpAuthentication::Token::ControllerMethods

        before_action :authenticate_api_token!
        before_action :set_current_user
        after_action :record_token_usage

        rescue_from ActiveRecord::RecordNotFound, with: :not_found
        rescue_from ActionController::ParameterMissing, with: :bad_request

        protected

        # Authenticate using Bearer token
        def authenticate_api_token!
          authenticate_with_http_token do |token, _options|
            @current_api_token = ApiToken.find_by_raw_token(token)
          end

          unless @current_api_token&.active?
            render json: {
              error: "unauthorized",
              message: "Invalid or expired API token"
            }, status: :unauthorized
          end
        end

        # Set current user from token
        def set_current_user
          @current_user = @current_api_token&.user
        end

        # Accessors
        def current_user
          @current_user
        end

        def current_api_token
          @current_api_token
        end

        # Check if token has required scope
        def require_scope!(scope)
          unless current_api_token&.has_scope?(scope)
            render json: {
              error: "forbidden",
              message: "Token does not have required scope: #{scope}"
            }, status: :forbidden
          end
        end

        # Record token usage after each request
        def record_token_usage
          current_api_token&.record_usage!(request.remote_ip)
        end

        # Standard error responses
        def not_found
          render json: {
            error: "not_found",
            message: "Resource not found"
          }, status: :not_found
        end

        def forbidden
          render json: {
            error: "forbidden",
            message: "Access denied"
          }, status: :forbidden
        end

        def bad_request(exception)
          render json: {
            error: "bad_request",
            message: exception.message
          }, status: :bad_request
        end

        # Helper methods for consistent response format
        def render_success(data, status: :ok)
          render json: data, status: status
        end

        def render_error(message, status: :unprocessable_entity, errors: nil)
          response = { error: "error", message: message }
          response[:errors] = errors if errors
          render json: response, status: status
        end
      end
    end
  end
end
