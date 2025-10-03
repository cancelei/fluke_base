class GithubCommitRefreshJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |exception|
    Rails.logger.error "GithubCommitRefreshJob failed: #{exception.message}\n#{exception.backtrace.join("\n")}"
    raise exception # Re-raise to mark job as failed
  end

  def perform(project_id, access_token, branch = nil)
    Rails.logger.info "GithubCommitRefreshJob starting for project_id: #{project_id}, branch: #{branch}"

    @project = Project.find_by(id: project_id)
    unless @project
      Rails.logger.error "Project not found with ID: #{project_id}"
      return
    end

    if branch.blank?
      Rails.logger.error "Branch cannot be blank for project ID: #{project_id}"
      return
    end

    Rails.logger.info "Starting commit refresh for project '#{@project.name}' (#{project_id}), branch: #{branch}"
    fetch_and_store_commits(access_token, branch: branch)
  rescue StandardError => e
    Rails.logger.error "Error in GithubCommitRefreshJob#perform: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    raise e
  end

  private

  def fetch_and_store_commits(access_token = nil, branch: nil)
    return 0 if @project.repository_url.blank?

    Rails.logger.info "Fetching commits for branch '#{branch}' in project '#{@project.name}' (#{@project.id})"
    Rails.logger.info "Repository URL: #{@project.repository_url}"

    service = GithubService.new(@project, access_token, branch: branch)
    Rails.logger.info "GithubService initialized, calling fetch_commits..."

    commits_data = service.fetch_commits
    Rails.logger.info "Service returned #{commits_data&.length || 0} commits"

    # The service returns the processed commits data, not the raw commits
    if commits_data.blank?
      Rails.logger.warn "No commits returned from service for branch '#{branch}' in project '#{@project.name}'"
      Rails.logger.warn "This could indicate: 1) No commits in branch, 2) API rate limit, 3) Authentication issues, 4) Repository access issues"
      return 0
    end

    Rails.logger.info "Commits data sample: #{commits_data.first&.slice(:commit_sha, :commit_message)&.inspect}"

    # Find or create the branch record
    Rails.logger.info "Looking up branch record for '#{branch}' in project '#{@project.name}'"
    db_branch = GithubBranch.find_by(project_id: @project.id, branch_name: branch)
    unless db_branch
      Rails.logger.error "Branch record not found for '#{branch}' in project '#{@project.name}' (#{@project.id})"
      Rails.logger.error "Available branches for this project: #{GithubBranch.where(project_id: @project.id).pluck(:branch_name)}"
      return 0
    end

    Rails.logger.info "Found branch record: #{db_branch.inspect}"

    begin
      # Store commits in database
      commit_shas = commits_data.map { |c| c[:commit_sha] }
      Rails.logger.info "Storing #{commits_data.length} commits for branch '#{branch}'"
      Rails.logger.info "Commit SHAs to store: #{commit_shas.first(5).join(', ')}#{commit_shas.length > 5 ? '...' : ''}"

      # Log the data being upserted
      commits_data.first(3).each_with_index do |commit_data, index|
        Rails.logger.debug "Commit #{index + 1}: #{commit_data.slice(:commit_sha, :commit_message, :commit_date, :lines_added, :lines_removed).inspect}"
      end

      result = GithubLog.upsert_all(
        commits_data.map { |c| c.merge(project_id: @project.id) },
        unique_by: [ :project_id, :commit_sha ]
      )
      Rails.logger.info "Upsert result: #{result.inspect}"
      Rails.logger.info "Successfully stored #{commits_data.size} commits in github_logs table"

      # Create branch-log relationships
      log_ids = GithubLog.where(project_id: @project.id, commit_sha: commit_shas).pluck(:id)
      Rails.logger.info "Creating branch-log relationships for #{log_ids.length} logs..."
      Rails.logger.info "Found #{log_ids.length} github_logs records for the commit SHAs"

      if log_ids.blank?
        Rails.logger.error "No github_logs records found after upsert! This indicates the upsert failed silently."
        Rails.logger.error "Looking for existing records with these SHAs:"
        existing_records = GithubLog.where(project_id: @project.id, commit_sha: commit_shas)
        Rails.logger.error "Found #{existing_records.count} existing records"
        return 0
      end

      github_branch_logs = log_ids.map { |id| { github_branch_id: db_branch.id, github_log_id: id } }
      Rails.logger.debug "Sample github_branch_logs data: #{github_branch_logs.first(3).inspect}"

      branch_log_result = GithubBranchLog.upsert_all(
        github_branch_logs,
        unique_by: [ :github_branch_id, :github_log_id ]
      )
      Rails.logger.info "Branch-log upsert result: #{branch_log_result.inspect}"
      Rails.logger.info "Successfully stored #{github_branch_logs.size} branch-log relationships in github_branch_logs table"

      Rails.logger.info "Stored #{commits_data.size} commits for branch '#{branch}' in project '#{@project.name}'"

      # Broadcast updated GitHub logs data
      Rails.logger.info "Broadcasting github updates..."
      broadcast_github_updates
      Rails.logger.info "Successfully broadcasted #{commits_data.size} commits for branch '#{branch}' in project '#{@project.name}'"

      commits_data.size
    rescue => e
      Rails.logger.error "Error storing commits: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Commits data length: #{commits_data&.length}"
      Rails.logger.error "Branch: #{branch}"
      Rails.logger.error "Project: #{@project.name} (#{@project.id})"
      0
    end
  end

  def broadcast_github_updates
    Rails.logger.info "Starting broadcast_github_updates for project '#{@project.name}'"

    # Recalculate stats and recent commits
    Rails.logger.debug "Fetching recent commits..."
    recent_commits = @project.github_logs.includes(:user, :github_branch_logs).order(commit_date: :desc).limit(15)
    Rails.logger.info "Found #{recent_commits.length} recent commits"

    total_commits = @project.github_logs.count
    total_additions = @project.github_logs.sum(:lines_added) || 0
    total_deletions = @project.github_logs.sum(:lines_removed) || 0
    last_updated = recent_commits.first&.commit_date || Time.current
    contributions = @project.github_contributions

    Rails.logger.info "Stats calculated: #{total_commits} commits, #{total_additions} additions, #{total_deletions} deletions"
    Rails.logger.debug "Sample recent commit: #{recent_commits.first&.slice(:commit_sha, :commit_message)&.inspect}"

    # Broadcast the updated GitHub logs list
    Rails.logger.info "Broadcasting github_logs list..."
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
    Rails.logger.info "Broadcasting github_stats..."
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
    Rails.logger.info "Broadcasting contributions_summary..."
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

    Rails.logger.info "Successfully completed broadcast_github_updates"
  rescue StandardError => e
    Rails.logger.error "Error in broadcast_github_updates: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    # Don't re-raise broadcast errors as they shouldn't fail the main job
  end
end
