# frozen_string_literal: true

module Github
  # Checks if a user has access to a specific GitHub repository
  #
  # This service validates repository access through:
  # 1. GitHub App installation (checks if repo is in user's installations)
  # 2. Legacy PAT token (validates via API call)
  #
  # Usage:
  #   result = Github::RepositoryAccessChecker.call(user: current_user, repository_url: "owner/repo")
  #   if result.success?
  #     # User has access
  #   else
  #     # result.failure[:needs_install] indicates user needs to install the app
  #   end
  #
  class RepositoryAccessChecker < Base
    GITHUB_APP_INSTALL_URL = "https://github.com/apps/flukebase/installations/new"

    def initialize(user:, repository_url:)
      @user = user
      @repository_url = repository_url
    end

    def call
      return failure_result(:no_connection, "No GitHub connection available") unless @user.github_connected?

      repo_path = extract_repo_path(@repository_url)
      return failure_result(:invalid_url, "Invalid repository URL") if repo_path.blank?

      # Check GitHub App installation first (preferred method)
      if @user.github_app_connected?
        check_installation_access(repo_path)
      else
        # Fall back to PAT-based access check
        check_pat_access(repo_path)
      end
    end

    private

    def check_installation_access(repo_path)
      installation = @user.installation_for_repo(repo_path)

      if installation
        Success({
          accessible: true,
          access_type: :github_app,
          installation_id: installation.installation_id,
          message: "Repository accessible via GitHub App"
        })
      else
        failure_result(
          :no_installation,
          "This repository is not accessible. Install FlukeBase on your GitHub account to grant access.",
          needs_install: true,
          install_url: GITHUB_APP_INSTALL_URL
        )
      end
    end

    def check_pat_access(repo_path)
      client = build_client(@user.github_token)

      with_api_error_handling do
        repo = client.repository(repo_path)

        Success({
          accessible: true,
          access_type: :personal_access_token,
          private: repo.private?,
          message: repo.private? ? "Private repository accessible via PAT" : "Public repository accessible"
        })
      end
    rescue Octokit::NotFound
      failure_result(
        :not_found,
        "Repository not found. It may be private and require a GitHub connection with access.",
        needs_install: true,
        install_url: GITHUB_APP_INSTALL_URL
      )
    rescue Octokit::Forbidden
      failure_result(
        :forbidden,
        "Access denied. You may need to install FlukeBase on this repository.",
        needs_install: true,
        install_url: GITHUB_APP_INSTALL_URL
      )
    end
  end
end
