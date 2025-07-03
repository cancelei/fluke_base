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
      Rails.logger.error "Branch cannot be blank"
      return
    end

    fetch_and_store_commits(access_token, branch: branch)
  end

  private

  def fetch_and_store_commits(access_token = nil, branch: nil)
    return 0 if @project.repository_url.blank?

    puts "Fetching commits for branch #{branch}"
    service = GithubService.new(@project, access_token, branch: branch)
    commits = service.fetch_commits
    puts "Getting these commits #{commits.length}"
    return 0 if commits.blank?

    # Find existing commit SHAs to avoid duplicates
    existing_shas = @project.github_logs.pluck(:commit_sha)
    new_commits = commits.reject { |c| existing_shas.include?(c[:commit_sha]) }

    # Bulk insert new commits

    if new_commits.any?
      begin
        GithubLog.upsert_all(
          new_commits.map { |c| c.merge(project_id: @project.id) },
          unique_by: [ :project_id, :commit_sha ]
        )
        Rails.logger.info "Stored #{new_commits.size} new commits for branch '#{branch}' in project '#{@project.name}'"
      rescue => e
        puts e
      end
    end

    new_commits.size
  end
end
