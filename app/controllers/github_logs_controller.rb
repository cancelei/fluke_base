class GithubLogsController < ApplicationController
  before_action :set_project
  before_action :authenticate_user!
  before_action :authorize_access!

  def index
    # Get filter parameters
    @selected_branch = params[:branch].presence
    @agreement_only = params[:agreement_only] == "1"

    # Get agreement user IDs if filtering by agreement
    agreement_user_ids = if @agreement_only
      # Include project owner and mentors with accepted agreements
      user_ids = []
      user_ids += @project.mentorships
                         .where(status: "Accepted")
                         .pluck(:initiator_id, :other_party_id)
      user_ids.flatten.uniq
    end

    # Build base query for recent commits
    recent_commits_query = @project.github_logs.includes(:user).order(commit_date: :desc)
    recent_commits_query = recent_commits_query.where(github_branches_id: @selected_branch) if @selected_branch.present? && @selected_branch.to_i != 0
    recent_commits_query = recent_commits_query.where(user_id: agreement_user_ids) if @agreement_only && agreement_user_ids.present?

    # Get recent commits for the activity feed with user preloading
    @recent_commits = recent_commits_query.limit(50)

    # Build base query for statistics
    stats_query = @project.github_logs
    stats_query = stats_query.where(github_branches_id: @selected_branch) if @selected_branch.present?
    stats_query = stats_query.where(user_id: agreement_user_ids) if @agreement_only && agreement_user_ids.present?

    # Calculate statistics
    @total_commits = stats_query.count
    @total_additions = stats_query.sum(:lines_added) || 0
    @total_deletions = stats_query.sum(:lines_removed) || 0
    @last_updated = @recent_commits.first&.commit_date || Time.current

    # Get contributions summary with user details and additional stats
    @contributions = @project.github_contributions(
      branch: @selected_branch,
      agreement_only: @agreement_only,
      agreement_user_ids: agreement_user_ids
    )

    # Get available branches for the dropdown
    @available_branches = @project.available_branches

    respond_to do |format|
      format.html
      format.json {
        render json: {
          contributions: @contributions,
          recent_commits: @recent_commits,
          stats: {
            total_commits: @total_commits,
            total_additions: @total_additions,
            total_deletions: @total_deletions,
            last_updated: @last_updated
          }
        }
      }
    end
  end

  def refresh
    # Queue the background job
    if params[:branch].present?
      branch = GithubBranch.find_by_id(params[:branch].to_i)

      if branch.nil?
        redirect_to project_github_logs_path(@project), alert: "Selected branch not found."
        return
      end

      if branch.branch_name.blank?
        redirect_to project_github_logs_path(@project), alert: "Branch name is missing for the selected branch."
        return
      end

      Rails.logger.info "Scheduling refresh for project #{@project.id}, branch: #{branch.branch_name}"
      GithubCommitRefreshJob.perform_later(@project.id, current_user.github_token, branch.branch_name)
      redirect_to project_github_logs_path(@project), notice: "Commit refresh has been queued for branch '#{branch.branch_name}'."
    else
      Rails.logger.info "Scheduling branch fetch for project #{@project.id}"
      GithubFetchBranchesJob.perform_later(@project.id, current_user.github_token)
      redirect_to project_github_logs_path(@project), notice: "Branch and commit refresh has been queued."
    end
  end

  def fetch_commits
    if current_user.github_token.blank?
      redirect_to project_github_logs_path(@project),
                  alert: "You need to connect your GitHub account first."
      return
    end

    # Get the selected branch from params
    count = @project.fetch_and_store_commits(current_user.github_token, branch: params[:branch].presence)

    respond_to do |format|
      format.html {
        if count.positive?
          redirect_to project_github_logs_path(@project),
                      notice: "Successfully fetched #{count} new #{"commit".pluralize(count)} from GitHub."
        else
          redirect_to project_github_logs_path(@project),
                      notice: "No new commits found or there was an error fetching commits."
        end
      }
      format.json {
        if count.positive?
          render json: { message: "Fetched #{count} new #{"commit".pluralize(count)}", count: count }
        else
          render json: { message: "No new commits found or there was an error", count: 0 }, status: :unprocessable_entity
        end
      }
    end
  rescue Octokit::Unauthorized
    respond_to do |format|
      format.html {
        redirect_to project_github_logs_path(@project),
                    alert: "GitHub authentication failed. Please check your GitHub token."
      }
      format.json {
        render json: { error: "GitHub authentication failed. Please check your GitHub token." },
               status: :unauthorized
      }
    end
  rescue Octokit::Error => e
    respond_to do |format|
      format.html {
        redirect_to project_github_logs_path(@project),
                    alert: "GitHub API error: #{e.message}"
      }
      format.json {
        render json: { error: "GitHub API error: #{e.message}" },
               status: :unprocessable_entity
      }
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def authorize_access!
    unless @project.can_view_github_logs?(current_user)
      redirect_to @project,
                  alert: "You don't have permission to view GitHub logs for this project."
    end
  end

  helper_method :current_branch

  def current_branch
    params[:branch].presence
  end
end
