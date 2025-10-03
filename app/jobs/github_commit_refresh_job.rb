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

    # Get job ID (fallback for manual/console execution)
    current_job_id = respond_to?(:job_id) ? job_id : SecureRandom.uuid
    job_id_short = current_job_id[0..7]

    # Use cache-based locking to prevent concurrent processing of the same branch
    # If another job is already processing this branch, skip this execution
    lock_key = "github_commit_refresh_lock:#{project_id}:#{branch}"

    # Try to acquire lock for 10 minutes (max expected processing time)
    acquired = Rails.cache.write(lock_key, current_job_id, unless_exist: true, expires_in: 10.minutes)

    unless acquired
      existing_job = Rails.cache.read(lock_key)
      Rails.logger.warn "[Job:#{job_id_short}] Skipping - another job (#{existing_job[0..7]}) is already processing project #{project_id}, branch: '#{branch}'"
      return
    end

    begin
      @job_id_short = job_id_short  # Make available to fetch_and_store_commits
      Rails.logger.info "[Job:#{job_id_short}] Starting commit refresh for project #{project_id}, branch: '#{branch}'"
      result = fetch_and_store_commits(access_token, branch: branch)
      Rails.logger.info "[Job:#{job_id_short}] Completed commit refresh for project #{project_id}, branch: '#{branch}' - #{result} commits processed"
      result
    ensure
      # Always release the lock when done
      Rails.cache.delete(lock_key)
    end
  end

  private

  def fetch_and_store_commits(access_token = nil, branch: nil)
    return 0 if @project.repository_url.blank?

    job_id_short = defined?(@job_id_short) ? @job_id_short : "manual"
    Rails.logger.info "[Job:#{job_id_short}] Fetching commits for branch '#{branch}' in project #{@project.id}"
    service = GithubService.new(@project, access_token, branch: branch)
    result = service.fetch_commits

    # Service now returns a hash with :commits (new commits to store) and :all_shas (all commits in branch)
    commits_data = result[:commits] || []
    all_commit_shas = result[:all_shas] || []

    if all_commit_shas.blank?
      Rails.logger.info "No commits found in branch #{branch}"
      return 0
    end

    # Find or create the branch record
    db_branch = GithubBranch.find_by(project_id: @project.id, branch_name: branch)
    unless db_branch
      Rails.logger.error "Branch record not found for #{branch} in project #{@project.id}"
      return 0
    end

    begin
      # Store only NEW commits in database (to minimize API detail fetches)
      if commits_data.any?
        Rails.logger.info "[Job:#{job_id_short}] Storing #{commits_data.length} new commits for branch '#{branch}'"
        GithubLog.upsert_all(
          commits_data.map { |c| c.merge(project_id: @project.id) },
          unique_by: :commit_sha
        )
      else
        Rails.logger.info "[Job:#{job_id_short}] No new commits to store for branch '#{branch}'"
      end

      # Create branch-log relationships for ALL commits that exist in this branch on GitHub
      # This ensures that shared commits (appearing in multiple branches) get associated with all branches
      Rails.logger.info "[Job:#{job_id_short}] Creating branch associations for #{all_commit_shas.size} commits in branch '#{branch}'"
      log_ids = GithubLog.where(project_id: @project.id, commit_sha: all_commit_shas).pluck(:id)

      if log_ids.any?
        github_branch_logs = log_ids.map { |id| { github_branch_id: db_branch.id, github_log_id: id } }
        GithubBranchLog.upsert_all(
          github_branch_logs,
          unique_by: [ :github_branch_id, :github_log_id ]
        )
        Rails.logger.info "[Job:#{job_id_short}] Created #{log_ids.size} branch-commit associations for branch '#{branch}'"
      else
        Rails.logger.warn "[Job:#{job_id_short}] No matching commits found in database for branch '#{branch}' SHAs"
      end

      # Broadcast updated GitHub logs data
      broadcast_github_updates

      Rails.logger.info "[Job:#{job_id_short}] Completed sync for branch '#{branch}': #{commits_data.size} new, #{all_commit_shas.size} total"

      all_commit_shas.size
    rescue => e
      Rails.logger.error "Error storing commits: #{e.message}\n#{e.backtrace.join("\n")}"
      0
    end
  end

  def broadcast_github_updates
    # Recalculate stats and recent commits
    recent_commits = @project.github_logs.includes(:user, :github_branch_logs).order(commit_date: :desc).limit(15)
    total_commits = @project.github_logs.count
    total_additions = @project.github_logs.sum(:lines_added) || 0
    total_deletions = @project.github_logs.sum(:lines_removed) || 0
    last_updated = recent_commits.first&.commit_date || Time.current
    contributions = @project.github_contributions

    # Broadcast the updated GitHub logs list
    Turbo::StreamsChannel.broadcast_replace_to(
      "project_#{@project.id}_github_commits",
      target: "github_logs",
      partial: "github_logs/commits_list",
      locals: {
        recent_commits: recent_commits,
        project: @project
      }
    )

    # Broadcast updated stats
    Turbo::StreamsChannel.broadcast_replace_to(
      "project_#{@project.id}_github_commits",
      target: "github_stats",
      partial: "github_logs/stats_section",
      locals: {
        total_commits: total_commits,
        total_additions: total_additions,
        total_deletions: total_deletions,
        last_updated: last_updated,
        project: @project
      }
    )

    # Broadcast updated contributions summary
    Turbo::StreamsChannel.broadcast_replace_to(
      "project_#{@project.id}_github_commits",
      target: "contributions_summary",
      partial: "github_logs/contributions_section",
      locals: {
        contributions: contributions,
        last_updated: last_updated,
        project: @project
      }
    )
  end
end
