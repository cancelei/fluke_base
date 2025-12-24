# frozen_string_literal: true

module Github
  # Generates an installation access token for a GitHub App installation
  #
  # Installation access tokens are used to make API calls on behalf of an installation
  # They expire after 1 hour and provide access to the repositories selected during installation
  #
  # Usage:
  #   result = Github::InstallationTokenService.call(installation_id: "12345")
  #   if result.success?
  #     token = result.value![:token]
  #     # Use token for API calls
  #   end
  #
  class InstallationTokenService < Base
    def initialize(installation_id:)
      @installation_id = installation_id
    end

    def call
      jwt_result = AppJwtGenerator.call
      return jwt_result if jwt_result.failure?

      jwt = jwt_result.value!
      client = Octokit::Client.new(bearer_token: jwt)

      with_api_error_handling do
        response = client.create_app_installation_access_token(@installation_id)

        Success({
          token: response.token,
          expires_at: response.expires_at,
          permissions: response.permissions.to_h,
          repositories: extract_repositories(response)
        })
      end
    end

    private

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
