class GithubFetchBranchesJob < ApplicationJob
  def perform(project_id, access_token)
    @project = Project.find(project_id)
    service = GithubService.new(@project, access_token)
    branches = service.fetch_branches_with_owner

    if branches.empty?
      Rails.logger.warn "No branches found for project #{project_id}"
      return
    end

    branches.each do |branch|
      if branch[:branch_name].present?
        GithubCommitRefreshJob.perform_later(@project.id, access_token, branch[:branch_name])
      else
        Rails.logger.error "Branch name is blank for branch in project #{project_id}"
      end
    end
  rescue => e
    Rails.logger.error "Error in GithubFetchBranchesJob: #{e.message}\n#{e.backtrace.join("\n")}"
    raise e
  end
end
