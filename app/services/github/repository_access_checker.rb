# frozen_string_literal: true

module Github
  # Checks if a user has access to a specific GitHub repository
  #
  # This service validates repository access through:
  # 1. Public repository check (no auth needed)
  # 2. GitHub App installation (checks if repo is in user's installations)
  # 3. Legacy PAT token (validates via API call)
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
    def initialize(user:, repository_url:)
      @user = user
      @repository_url = repository_url
    end

    def call
      repo_path = extract_repo_path(@repository_url)
      return failure_result(:invalid_url, "Invalid repository URL") if repo_path.blank?

      # Step 1: Check if repo is public (no auth needed)
      public_check = check_public_repository(repo_path)
      return public_check if public_check.success? && public_check.value![:public] == true

      # Step 2: For private repos or unknown, user needs GitHub connection
      return failure_result(
        :no_connection,
        "Private repository detected. Connect your GitHub account to access it.",
        needs_install: true,
        install_url: AppConfig.install_url
      ) unless @user.github_connected?

      # Step 3: Check private access via GitHub App or PAT
      if @user.github_app_connected?
        check_installation_access(repo_path)
      else
        check_pat_access(repo_path)
      end
    end

    private

    # Check if repository is public using unauthenticated API call
    # This allows public repos to be added without requiring GitHub auth
    def check_public_repository(repo_path)
      client = Octokit::Client.new  # No authentication
      repo = client.repository(repo_path)

      if repo.private?
        # Repo exists but is private - needs auth
        Success({ public: false, private: true, needs_auth: true })
      else
        # Public repo - no auth needed
        Success({
          accessible: true,
          public: true,
          private: false,
          access_type: :public,
          message: "Public repository - no authentication needed"
        })
      end
    rescue Octokit::NotFound
      # Repo doesn't exist OR is private (GitHub returns 404 for private repos without auth)
      Success({ public: false, private: true, needs_auth: true })
    rescue Octokit::TooManyRequests => e
      # Rate limited - fall through to authenticated check
      log("Public check rate limited, falling back to auth check", level: :warn)
      Success({ public: false, needs_auth: true, rate_limited: true })
    rescue Octokit::Error => e
      # Other errors - fall through to authenticated check
      log("Public check failed: #{e.message}", level: :warn)
      Success({ public: false, needs_auth: true, error: e.message })
    end

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
          install_url: AppConfig.install_url
        )
      end
    end

    def check_pat_access(repo_path)
      client = build_client(@user.effective_github_token)

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
        install_url: AppConfig.install_url
      )
    rescue Octokit::Forbidden
      failure_result(
        :forbidden,
        "Access denied. You may need to install FlukeBase on this repository.",
        needs_install: true,
        install_url: AppConfig.install_url
      )
    end
  end
end
