class GithubCommitRefreshJob < ApplicationJob
  def perform(project_id, access_token, branch = nil)
    @project = Project.find(project_id)
    return if branch.nil?

    fetch_and_store_commits(access_token, branch: branch)
  rescue => e
    raise e
  end


  private

  def fetch_and_store_commits(access_token = nil, branch: nil)
    return 0 unless repository_url.present?

    service = GithubService.new(@project, access_token, branch: branch)

    commits = service.fetch_commits
    return 0 unless commits.any?

    # Find existing commit SHAs to avoid duplicates
    existing_shas = github_logs.pluck(:commit_sha)
    new_commits = commits.reject { |c| existing_shas.include?(c[:commit_sha]) }

    # Bulk insert new commits
    GithubLog.upsert_all(commits, unique_by: [ :project_id, :commit_sha, :agreement_id, :user_id ])

    puts "Stored #{new_commits.size} new commits for branch '#{branch}' in project '#{name}'"

    # Return the number of new commits stored
    new_commits.size
  end
end
