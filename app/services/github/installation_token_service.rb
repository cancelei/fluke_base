# frozen_string_literal: true

module Github
  # Generates an installation access token for a GitHub App installation
  #
  # Installation access tokens are used to make API calls on behalf of an installation.
  # Per GitHub's best practices:
  # - Use installation tokens for automated/background tasks (attributed to app)
  # - Tokens expire after 1 hour
  # - Cache tokens to avoid unnecessary API calls
  #
  # See: https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/about-authentication-with-a-github-app
  #
  # Usage:
  #   result = Github::InstallationTokenService.call(installation_id: "12345")
  #   if result.success?
  #     token = result.value![:token]
  #     # Use token for API calls
  #   end
  #
  #   # Or use the cached version for background jobs:
  #   result = Github::InstallationTokenService.call(installation_id: "12345", use_cache: true)
  #
  class InstallationTokenService < Base
    # Cache tokens for 50 minutes (they expire at 60 minutes)
    CACHE_TTL = 50.minutes
    CACHE_KEY_PREFIX = "github:installation_token"

    def initialize(installation_id:, use_cache: true)
      @installation_id = installation_id.to_s
      @use_cache = use_cache
    end

    def call
      return fetch_cached_token if @use_cache && cached_token_valid?

      generate_new_token
    end

    # Class method to get an Octokit client for background operations
    # This uses installation tokens (app-attributed) instead of user tokens
    def self.client_for_installation(installation_id)
      result = call(installation_id:)
      return nil if result.failure?

      Octokit::Client.new(access_token: result.value![:token])
    end

    # Get client for a specific repository via user's installations
    def self.client_for_repo(user:, repo_full_name:)
      installation = user.installation_for_repo(repo_full_name)
      return nil unless installation

      client_for_installation(installation.installation_id)
    end

    private

    def cache_key
      "#{CACHE_KEY_PREFIX}:#{@installation_id}"
    end

    def cached_token_valid?
      return false unless Rails.cache.exist?(cache_key)

      cached = Rails.cache.read(cache_key)
      cached && cached[:expires_at] > 5.minutes.from_now
    end

    def fetch_cached_token
      cached = Rails.cache.read(cache_key)
      Success(cached)
    end

    def generate_new_token
      jwt_result = AppJwtGenerator.call
      return jwt_result if jwt_result.failure?

      jwt = jwt_result.value!
      client = Octokit::Client.new(bearer_token: jwt)

      with_api_error_handling do
        response = client.create_app_installation_access_token(@installation_id)

        token_data = {
          token: response.token,
          expires_at: response.expires_at,
          permissions: response.permissions.to_h,
          repositories: extract_repositories(response),
          generated_at: Time.current
        }

        # Cache the token if caching is enabled
        if @use_cache
          Rails.cache.write(cache_key, token_data, expires_in: CACHE_TTL)
        end

        Success(token_data)
      end
    end

    def extract_repositories(response)
      return [] unless response.respond_to?(:repositories)

      response.repositories.map do |repo|
        {
          id: repo.id,
          name: repo.name,
          full_name: repo.full_name,
          private: repo.private
        }
      end
    end
  end
end
