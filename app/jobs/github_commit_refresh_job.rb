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

    Rails.logger.info "Fetching commits for branch #{branch} in project #{@project.id}"
    service = GithubService.new(@project, access_token, branch: branch)
    commits = service.fetch_commits
    commit_shas = commits.map { |c| c[:commit_sha] }
    branch_id = GithubBranch.find_by(project_id: @project.id, branch_name: branch).id
    Rails.logger.info "Found #{commits.length} commits for branch #{branch}"
    puts commits.length
    return 0 if commits.blank?
      begin
        GithubLog.upsert_all(
          commits.map { |c| c.merge(project_id: @project.id) },
          unique_by: [ :project_id, :commit_sha ]
        )
        log_ids = GithubLog.where(project_id: @project.id, commit_sha: commit_shas).pluck(:id)
        github_branch_logs = log_ids.map { |id| { github_branch_id: branch_id, github_log_id: id } }
        puts github_branch_logs
        GithubBranchLog.upsert_all(
          github_branch_logs,
          unique_by: [ :github_branch_id, :github_log_id ]
        )

        Rails.logger.info "Stored #{commits.size} commits for branch '#{branch}' in project '#{@project.name}'"

        Turbo::StreamsChannel.broadcast_replace_to(
          "project_#{@project.id}_github_commits",
          target: "github-commits-reload",
          partial: "github_logs/github_commits_reload"
        )
      rescue => e
        puts "Error storing commits: #{e.message}\n#{e.backtrace.join("\n")}"
      end
  end
end
