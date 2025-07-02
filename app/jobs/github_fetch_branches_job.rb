class GithubFetchBranchesJob < ApplicationJob

  def perform(project_id, access_token)
    @project = Project.find(project_id)
    service = GithubService.new(@project, access_token)
    branches = service.fetch_branches_with_owner
    branches.each do |branch|
      GithubCommitRefreshJob.perform_later(@project.id, access_token, branch[:branch_name])
    end
  rescue => e
    raise e
  end
end
