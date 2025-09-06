class GithubFetchBranchesJob < ApplicationJob
  def perform(project_id, access_token)
    @project = Project.find(project_id)
    service = GithubService.new(@project, access_token)
    branches = service.fetch_branches_with_owner

    if branches.empty?
      Rails.logger.warn "No branches found for project #{project_id}"
      broadcast_empty_state
      return
    end

    # Check if this is the first time gathering data for this repository
    is_first_time = @project.github_branches.empty?

    if is_first_time
      # Broadcast initial template for smooth updates
      broadcast_initial_template
    end

    branches.each do |branch|
      if branch[:branch_name].present?
        Rails.logger.info "Enqueuing GithubCommitRefreshJob for project #{project_id}, branch: #{branch[:branch_name]}"
        job = GithubCommitRefreshJob.perform_later(@project.id, access_token, branch[:branch_name])
        Rails.logger.info "Job enqueued with ID: #{job.job_id}"
      else
        Rails.logger.error "Branch name is blank for branch in project #{project_id}"
      end
    end

    Rails.logger.info "Finished enqueuing #{branches.size} commit refresh jobs for project #{project_id}"
  rescue => e
    Rails.logger.error "Error in GithubFetchBranchesJob: #{e.message}\n#{e.backtrace.join("\n")}"
    raise e
  end

  private

  def broadcast_initial_template
    # Broadcast loading state for new repositories
    Turbo::StreamsChannel.broadcast_replace_to(
      "project_#{@project.id}_github_commits",
      target: "github_logs",
      partial: "github_logs/loading_state",
      locals: { project: @project }
    )

    # Initialize empty stats that will be updated as data arrives
    Turbo::StreamsChannel.broadcast_replace_to(
      "project_#{@project.id}_github_commits",
      target: "github_stats",
      partial: "github_logs/stats_section",
      locals: {
        total_commits: 0,
        total_additions: 0,
        total_deletions: 0,
        last_updated: Time.current,
        project: @project
      }
    )
  end

  def broadcast_empty_state
    # Broadcast empty state when no branches are found
    Turbo::StreamsChannel.broadcast_replace_to(
      "project_#{@project.id}_github_commits",
      target: "github_logs",
      partial: "github_logs/empty_state",
      locals: { project: @project, job_context: true }
    )
  end
end
