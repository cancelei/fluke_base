# frozen_string_literal: true

# Background job for refreshing GitHub commits for a specific branch
#
# Uses Github::CommitsFetcher for API calls and Github::BroadcastService
# for Turbo Stream updates.
#
# Features:
# - Cache-based locking to prevent concurrent processing
# - SHA-based deduplication for efficient syncing
# - Automatic branch-log associations
#
class GithubCommitRefreshJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |exception|
    Rails.logger.error "GithubCommitRefreshJob failed: #{exception.message}\n#{exception.backtrace.join("\n")}"
    raise exception # Re-raise to mark job as failed
  end

  def perform(project_id, access_token, branch = nil)
    @project = Project.find_by(id: project_id)
    unless @project
      Rails.logger.error "Project not found with ID: #{project_id}"
      return
    end

    if branch.blank?
      Rails.logger.error "Branch cannot be blank for project ID: #{project_id}"
      return
    end

    @access_token = access_token
    @branch = branch

    with_lock(project_id, branch) do
      fetch_and_store_commits
    end
  end

  private

  def with_lock(project_id, branch)
    current_job_id = respond_to?(:job_id) ? job_id : SecureRandom.uuid
    @job_id_short = current_job_id[0..7]
    lock_key = "github_commit_refresh_lock:#{project_id}:#{branch}"

    acquired = Rails.cache.write(lock_key, current_job_id, unless_exist: true, expires_in: 10.minutes)

    unless acquired
      existing_job = Rails.cache.read(lock_key)
      log_warn "Skipping - another job (#{existing_job[0..7]}) is already processing project #{project_id}, branch: '#{branch}'"
      return 0
    end

    begin
      log_info "Starting commit refresh for project #{@project.id}, branch: '#{@branch}'"
      result = yield
      log_info "Completed commit refresh for project #{@project.id}, branch: '#{@branch}' - #{result} commits processed"
      result
    ensure
      Rails.cache.delete(lock_key)
    end
  end

  def fetch_and_store_commits
    return 0 if @project.repository_url.blank?

    # Use the new CommitsFetcher service
    fetcher = Github::CommitsFetcher.new(
      project: @project,
      access_token: @access_token,
      branch: @branch
    )
    result = fetcher.call

    if result.failure?
      error_info = result.failure
      log_error "Failed to fetch commits: #{error_info[:message]}"
      return 0
    end

    data = result.value!
    commits_data = data[:commits] || []
    all_commit_shas = data[:all_shas] || []

    if all_commit_shas.blank?
      log_info "No commits found in branch #{@branch}"
      return 0
    end

    store_commits_and_associations(commits_data, all_commit_shas)
  end

  def store_commits_and_associations(commits_data, all_commit_shas)
    db_branch = GithubBranch.find_by(project_id: @project.id, branch_name: @branch)
    unless db_branch
      log_error "Branch record not found for #{@branch} in project #{@project.id}"
      return 0
    end

    begin
      store_new_commits(commits_data)
      create_branch_associations(db_branch, all_commit_shas)

      # Use BroadcastService for Turbo Stream updates
      Github::BroadcastService.new(@project).broadcast_updates

      log_info "Completed sync for branch '#{@branch}': #{commits_data.size} new, #{all_commit_shas.size} total"
      all_commit_shas.size
    rescue => e
      log_error "Error storing commits: #{e.message}\n#{e.backtrace.join("\n")}"
      0
    end
  end

  def store_new_commits(commits_data)
    if commits_data.any?
      log_info "Storing #{commits_data.length} new commits for branch '#{@branch}'"
      GithubLog.upsert_all(
        commits_data.map { |c| c.merge(project_id: @project.id) },
        unique_by: :commit_sha
      )
    else
      log_info "No new commits to store for branch '#{@branch}'"
    end
  end

  def create_branch_associations(db_branch, all_commit_shas)
    log_info "Creating branch associations for #{all_commit_shas.size} commits in branch '#{@branch}'"
    log_ids = GithubLog.where(project_id: @project.id, commit_sha: all_commit_shas).pluck(:id)

    if log_ids.any?
      github_branch_logs = log_ids.map { |id| { github_branch_id: db_branch.id, github_log_id: id } }
      GithubBranchLog.upsert_all(
        github_branch_logs,
        unique_by: [:github_branch_id, :github_log_id]
      )
      log_info "Created #{log_ids.size} branch-commit associations for branch '#{@branch}'"
    else
      log_warn "No matching commits found in database for branch '#{@branch}' SHAs"
    end
  end

  def log_info(message)
    Rails.logger.info "[Job:#{@job_id_short}] #{message}"
  end

  def log_warn(message)
    Rails.logger.warn "[Job:#{@job_id_short}] #{message}"
  end

  def log_error(message)
    Rails.logger.error "[Job:#{@job_id_short}] #{message}"
  end
end
