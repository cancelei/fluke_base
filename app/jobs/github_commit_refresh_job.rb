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

    Rails.logger.info "Starting commit refresh for project #{project_id}, branch: #{branch}"
    fetch_and_store_commits(access_token, branch: branch)
  end

  private

  def fetch_and_store_commits(access_token = nil, branch: nil)
    return 0 if @project.repository_url.blank?

    db_branch = GithubBranch.find_by(project_id: @project.id, branch_name: branch)

    # Find or create the branch record
    unless db_branch
      Rails.logger.error "Branch record not found for #{branch} in project #{@project.id}"
      return 0
    end

    Rails.logger.info "Fetching commits for branch #{branch} in project #{@project.id}"
    service = GithubService.new(@project, access_token, branch: branch, since: db_branch.latest_commit&.commit_date)
    commits_data = service.fetch_commits

    # The service returns the processed commits data, not the raw commits
    if commits_data.blank?
      Rails.logger.info "No commits returned from service for branch #{branch}"
      return 0
    end

    begin
      # Store commits in database
      commit_shas = commits_data.map { |c| c[:commit_sha] }
      Rails.logger.info "Storing #{commits_data.length} commits for branch #{branch}"

      GithubLog.upsert_all(
        commits_data.map { |c| c.merge(project_id: @project.id) },
        unique_by: [ :project_id, :commit_sha ]
      )

      # Create branch-log relationships
      log_ids = GithubLog.where(project_id: @project.id, commit_sha: commit_shas).pluck(:id)
      github_branch_logs = log_ids.map { |id| { github_branch_id: db_branch.id, github_log_id: id } }

      GithubBranchLog.upsert_all(
        github_branch_logs,
        unique_by: [ :github_branch_id, :github_log_id ]
      )

      Rails.logger.info "Stored #{commits_data.size} commits for branch '#{branch}' in project '#{@project.name}'"

      # Broadcast updated GitHub logs data
      broadcast_github_updates

      Rails.logger.info "Broadcasted #{commits_data.size} commits for branch '#{branch}' in project '#{@project.name}'"

      commits_data.size
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
