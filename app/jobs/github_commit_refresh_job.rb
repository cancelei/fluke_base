class GithubCommitRefreshJob < ApplicationJob
  queue_as :default

  def perform(project_id, access_token, branch = "main")
    project = Project.find(project_id)
    project.fetch_and_store_commits(access_token, branch: branch)
  rescue => e
    raise e
  end
end
