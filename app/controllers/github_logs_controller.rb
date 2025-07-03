class GithubLogsController < ApplicationController
  before_action :set_project
  before_action :authenticate_user!
  before_action :authorize_access!

  def index
    # Get the selected branch from params or default to nil (all branches)
    @selected_branch = params[:branch].presence

    # Build base query for recent commits
    recent_commits_query = @project.github_logs.includes(:user).order(commit_date: :desc)
    recent_commits_query = recent_commits_query.where(github_branches_id: @selected_branch) if @selected_branch.present?

    # Get recent commits for the activity feed with user preloading
    @recent_commits = recent_commits_query.limit(50)

    # Build base query for statistics
    stats_query = @project.github_logs
    stats_query = stats_query.where(github_branches_id: @selected_branch) if @selected_branch.present?

    # Calculate statistics
    @total_commits = stats_query.count
    @total_additions = stats_query.sum(:lines_added) || 0
    @total_deletions = stats_query.sum(:lines_removed) || 0
    @last_updated = @recent_commits.first&.commit_date || Time.current

    # Get contributions summary with user details and additional stats
    @contributions = @project.github_contributions(branch: @selected_branch)

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
    if params[:branch]
      branch_name = GithubBranch.find_by_id(params[:branch].to_i).branch_name
      GithubCommitRefreshJob.perform_later(@project.id, current_user.github_token, branch_name)
    else
      GithubFetchBranchesJob.perform_later(@project.id, current_user.github_token)
    end


    # Set up a polling interval for job status updates
    redirect_to project_github_logs_path(@project), notice: "Commit refresh has been queued."
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
