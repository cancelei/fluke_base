# frozen_string_literal: true

module Github
  # Refreshes an expired user access token using the refresh token
  #
  # GitHub App user access tokens expire after 8 hours
  # Refresh tokens last 6 months and can be used to get new access tokens
  #
  # Error codes returned:
  # - :no_refresh_token - User has no refresh token stored
  # - :refresh_token_expired - Refresh token has expired (6 months), user needs to re-auth
  # - :refresh_failed - GitHub API returned an error
  # - :refresh_error - Unexpected error during refresh
  #
  # Usage:
  #   result = Github::TokenRefreshService.call(user: current_user)
  #   if result.success?
  #     new_token = result.value!
  #   elsif result.failure[:error] == :refresh_token_expired
  #     # Prompt user to re-authenticate with GitHub
  #   end
  #
  class TokenRefreshService < ApplicationService
    GITHUB_TOKEN_URL = "https://github.com/login/oauth/access_token"

    # GitHub refresh tokens expire after 6 months
    REFRESH_TOKEN_LIFETIME = 6.months

    # Errors that indicate the refresh token has expired
    EXPIRED_TOKEN_ERRORS = [
      "bad_refresh_token",
      "The refresh token has expired",
      "refresh_token is expired"
    ].freeze

    def initialize(user:)
      @user = user
    end

    def call
      return failure_result(:no_refresh_token, "No refresh token available") unless @user.github_refresh_token

      # Check if refresh token is known to be expired
      if refresh_token_expired?
        invalidate_github_connection!
        return failure_result(:refresh_token_expired, "GitHub connection has expired. Please reconnect your GitHub account.")
      end

      response = exchange_refresh_token

      # Handle expired token errors from GitHub
      if expired_token_error?(response)
        invalidate_github_connection!
        return failure_result(:refresh_token_expired, "GitHub connection has expired. Please reconnect your GitHub account.")
      end

      return failure_result(:refresh_failed, response[:error_description] || response[:error]) if response[:error]

      update_user_tokens(response)

      Success(@user.github_user_access_token)
    rescue StandardError => e
      Rails.logger.error "[Github::TokenRefreshService] Failed to refresh token: #{e.message}"
      failure_result(:refresh_error, e.message)
    end

    private

    def refresh_token_expired?
      return false unless @user.github_refresh_token_expires_at.present?

      @user.github_refresh_token_expires_at < Time.current
    end

    def expired_token_error?(response)
      error = response[:error].to_s
      error_description = response[:error_description].to_s

      EXPIRED_TOKEN_ERRORS.any? do |msg|
        error.include?(msg) || error_description.include?(msg)
      end
    end

    def invalidate_github_connection!
      Rails.logger.warn "[Github::TokenRefreshService] Refresh token expired for user #{@user.id}, invalidating connection"

      @user.update!(
        github_user_access_token: nil,
        github_token_expires_at: nil
        # Keep refresh token and expiry for audit purposes
      )
    end

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
        github_token_expires_at: Time.current + response[:expires_in].to_i.seconds,
        # Refresh token also has a new expiry (6 months from now)
        github_refresh_token_expires_at: Time.current + (response[:refresh_token_expires_in]&.to_i&.seconds || REFRESH_TOKEN_LIFETIME)
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
