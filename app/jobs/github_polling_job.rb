# frozen_string_literal: true

# Recurring job that polls all eligible GitHub repositories for new commits and new branches.
# Runs every 60 seconds via Solid Queue recurring jobs.
# Uses the existing GithubCommitRefreshJob for commit fetching and Github::BranchesFetcher for branch discovery.
#
# Token Strategy (per GitHub best practices):
# - Prefers Installation Access Tokens for background tasks (app-attributed, higher rate limits)
# - Falls back to User Access Tokens if no installation is available
# - Falls back to legacy PAT as last resort
#
# See: https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/about-authentication-with-a-github-app
class GithubPollingJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[GithubPolling] Starting scheduled poll cycle"

    eligible_projects = find_eligible_projects
    if eligible_projects.empty?
      Rails.logger.info "[GithubPolling] No eligible projects found"
      return
    end

    Rails.logger.info "[GithubPolling] Found #{eligible_projects.count} eligible projects"

    eligible_projects.each do |project|
      poll_project(project)
    end

    Rails.logger.info "[GithubPolling] Completed poll cycle for #{eligible_projects.count} projects"
  end

  private

  # Find projects that are eligible for polling:
  # - Have a repository_url configured
  # - Owner has a valid GitHub token (OAuth or PAT) OR has GitHub App installation
  # - Haven't been polled in the last 50 seconds (prevents overlap)
  # - Either have branches already OR have no branches (to discover initial branches)
  def find_eligible_projects
    Project.joins(:user)
           .where.not(repository_url: [nil, ""])
           .where(
             "(users.github_user_access_token IS NOT NULL AND users.github_user_access_token != '') " \
             "OR (users.github_token IS NOT NULL AND users.github_token != '')"
           )
           .where("projects.github_last_polled_at IS NULL OR projects.github_last_polled_at < ?", 50.seconds.ago)
           .distinct
           .order(Arel.sql("projects.github_last_polled_at ASC NULLS FIRST"))
  end

  # Poll a single project for new commits and new branches
  def poll_project(project)
    # Get the best available token for this project
    # Prefers installation tokens for background tasks per GitHub best practices
    token_info = get_access_token_for_project(project)

    if token_info.nil?
      Rails.logger.warn "[GithubPolling] No valid token available for project #{project.id}"
      return
    end

    token = token_info[:token]
    token_type = token_info[:type]

    Rails.logger.debug "[GithubPolling] Using #{token_type} token for project #{project.id}"

    # Update polling timestamp before starting to prevent concurrent polls
    project.update_column(:github_last_polled_at, Time.current)

    # First, check for new branches (run every 10 minutes to avoid API rate limits)
    if should_check_for_new_branches?(project)
      check_for_new_branches(project, token)
    end

    # Then poll up to 3 branches per project for new commits (to manage API rate limits)
    # GithubBranch records are ordered by created_at, so main/develop branches come first
    branches = project.github_branches.limit(3)

    branches.each do |branch|
      next if branch.branch_name.blank?

      # Use the existing job which handles locking and deduplication
      GithubCommitRefreshJob.perform_later(project.id, token, branch.branch_name)
    end

    Rails.logger.info "[GithubPolling] Enqueued refresh for project #{project.id} (#{branches.count} branches, using #{token_type})"
  rescue => e
    Rails.logger.error "[GithubPolling] Error polling project #{project.id}: #{e.message}"
  end

  # Get the best available access token for a project
  # Priority:
  # 1. Installation Access Token (app-attributed, best for automation)
  # 2. User Access Token (refreshed if needed)
  # 3. Legacy PAT
  def get_access_token_for_project(project)
    user = project.user
    repo_full_name = Github::Base.new.send(:extract_repo_name, project.repository_url)

    # Try to get an installation token first (preferred for background tasks)
    installation_token = get_installation_token(user, repo_full_name)
    return { token: installation_token, type: :installation } if installation_token

    # Fall back to user token
    user_token = user.effective_github_token
    if user_token.present?
      return { token: user_token, type: user.github_app_connected? ? :user_oauth : :legacy_pat }
    end

    nil
  end

  # Get an installation access token for a repository
  def get_installation_token(user, repo_full_name)
    return nil unless repo_full_name.present?

    installation = user.installation_for_repo(repo_full_name)
    return nil unless installation

    result = Github::InstallationTokenService.call(
      installation_id: installation.installation_id,
      use_cache: true
    )

    result.success? ? result.value![:token] : nil
  rescue => e
    Rails.logger.warn "[GithubPolling] Failed to get installation token: #{e.message}"
    nil
  end

  # Check if we should look for new branches (every 10 minutes to avoid API rate limits)
  def should_check_for_new_branches?(project)
    return true unless project.github_branches.exists? # First time setup

    # Check if we haven't checked for branches in the last 10 minutes
    last_branch_check = project.github_branches.maximum(:updated_at)
    last_branch_check ||= project.created_at

    last_branch_check < 10.minutes.ago
  end

  # Check for new branches and fetch them if found
  def check_for_new_branches(project, token)
    Rails.logger.info "[GithubPolling] Checking for new branches in project #{project.id}"

    # Use the existing BranchesFetcher to discover new branches
    result = Github::BranchesFetcher.new(
      project:,
      access_token: token
    ).call

    if result.success?
      new_branches = result.value!
      if new_branches.any?
        Rails.logger.info "[GithubPolling] Found #{new_branches.count} new branches for project #{project.id}"

        # Trigger commit fetching for the new branches
        new_branches.each do |branch_data|
          GithubCommitRefreshJob.perform_later(project.id, token, branch_data[:branch_name])
        end
      else
        Rails.logger.info "[GithubPolling] No new branches found for project #{project.id}"
      end
    else
      Rails.logger.error "[GithubPolling] Failed to fetch branches for project #{project.id}: #{result.failure[:message]}"
    end
  rescue => e
    Rails.logger.error "[GithubPolling] Error checking for new branches in project #{project.id}: #{e.message}"
  end
end
