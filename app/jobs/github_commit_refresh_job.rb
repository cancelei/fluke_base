class GithubCommitRefreshJob < ApplicationJob
  queue_as :default

  def perform(project_id)
    project = Project.find(project_id)
    project.fetch_and_store_commits
  rescue => e
    job_status.update!(status: "failed", error_message: e.message)
    raise
  end
end
