# frozen_string_literal: true

module Github
  # Refreshes an expired user access token using the refresh token
  #
  # GitHub App user access tokens expire after 8 hours
  # Refresh tokens last 6 months and can be used to get new access tokens
  #
  # Usage:
  #   result = Github::TokenRefreshService.call(user: current_user)
  #   if result.success?
  #     new_token = result.value!
  #   end
  #
  class TokenRefreshService < ApplicationService
    GITHUB_TOKEN_URL = "https://github.com/login/oauth/access_token"

    def initialize(user:)
      @user = user
    end

    def call
      return failure_result(:no_refresh_token, "No refresh token available") unless @user.github_refresh_token

      response = exchange_refresh_token
      return failure_result(:refresh_failed, response[:error_description] || response[:error]) if response[:error]

      update_user_tokens(response)

      Success(@user.github_user_access_token)
    rescue StandardError => e
      Rails.logger.error "[Github::TokenRefreshService] Failed to refresh token: #{e.message}"
      failure_result(:refresh_error, e.message)
    end

    private

    def exchange_refresh_token
      response = HTTParty.post(
        GITHUB_TOKEN_URL,
        headers: {
          "Accept" => "application/json",
          "Content-Type" => "application/x-www-form-urlencoded"
        },
        body: {
          client_id:,
          client_secret:,
          grant_type: "refresh_token",
          refresh_token: @user.github_refresh_token
        }
      )

      JSON.parse(response.body, symbolize_names: true)
    end

    def update_user_tokens(response)
      @user.update!(
        github_user_access_token: response[:access_token],
        github_refresh_token: response[:refresh_token],
        github_token_expires_at: Time.current + response[:expires_in].to_i.seconds
      )
    end

    def client_id
      Github::AppConfig.client_id
    end

    def client_secret
      Github::AppConfig.client_secret
    end
  end
end
