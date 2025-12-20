# frozen_string_literal: true

# Recurring job that polls all eligible GitHub repositories for new commits.
# Runs every 60 seconds via Solid Queue recurring jobs.
# Uses the existing GithubCommitRefreshJob for actual commit fetching.
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
  # - Have at least one branch already fetched
  # - Owner has a valid github_token
  # - Haven't been polled in the last 50 seconds (prevents overlap)
  def find_eligible_projects
    Project.joins(:user, :github_branches)
           .where.not(repository_url: [nil, ""])
           .where.not(users: { github_token: [nil, ""] })
           .where("projects.github_last_polled_at IS NULL OR projects.github_last_polled_at < ?", 50.seconds.ago)
           .distinct
           .order(Arel.sql("projects.github_last_polled_at ASC NULLS FIRST"))
  end

  # Poll a single project for new commits
  def poll_project(project)
    token = project.user.github_token

    # Update polling timestamp before starting to prevent concurrent polls
    project.update_column(:github_last_polled_at, Time.current)

    # Poll up to 3 branches per project (to manage API rate limits)
    # GithubBranch records are ordered by created_at, so main/develop branches come first
    branches = project.github_branches.limit(3)

    branches.each do |branch|
      next if branch.branch_name.blank?

      # Use the existing job which handles locking and deduplication
      GithubCommitRefreshJob.perform_later(project.id, token, branch.branch_name)
    end

    Rails.logger.info "[GithubPolling] Enqueued refresh for project #{project.id} (#{branches.count} branches)"
  rescue => e
    Rails.logger.error "[GithubPolling] Error polling project #{project.id}: #{e.message}"
  end
end
