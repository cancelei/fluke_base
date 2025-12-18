class GithubLogsController < ApplicationController
  before_action :set_project
  before_action :authenticate_user!
  before_action :authorize_access!

  def index
    # Get filter parameters
    @selected_branch = params[:branch].presence
    @agreement_only = params[:agreement_only].presence
    @user_name = params[:user_name].presence

    # Get agreement user IDs if filtering by agreement
    agreement_user_ids = if @agreement_only
      # Include project owner and mentors with accepted agreements
      user_ids = []
      user_ids += @project.mentorships
                         .where(status: "Accepted")
                         .joins(:agreement_participants)
                         .pluck("agreement_participants.user_id")
      user_ids.flatten.uniq
    end

    # Build base query for recent commits
    recent_commits_query = @project.github_logs.includes(:user, :github_branch_logs).order(commit_date: :desc)
    recent_commits_query = recent_commits_query.where(github_branch_logs: { github_branch_id: @selected_branch }) if @selected_branch.present? && @selected_branch.to_i != 0
    recent_commits_query = recent_commits_query.where(unregistered_user_name: @user_name) if @user_name.present?
    recent_commits_query = recent_commits_query.where(user_id: agreement_user_ids) if @agreement_only

    # Get recent commits for the activity feed with user preloading and pagination
    @recent_commits = recent_commits_query.page(params[:page]).per(15)

    # Build base query for statistics - avoid double-counting commits in multiple branches
    stats_query = @project.github_logs
    stats_query = stats_query.joins(:github_branch_logs).where(github_branch_logs: { github_branch_id: @selected_branch }) if @selected_branch.present? && @selected_branch.to_i != 0
    stats_query = stats_query.where(unregistered_user_name: @user_name) if @user_name.present?
    stats_query = stats_query.where(user_id: agreement_user_ids) if @agreement_only

    # Use distinct to avoid double-counting commits that appear in multiple branches
    stats_query = stats_query.distinct

    # Calculate statistics
    @total_commits = stats_query.count
    @total_additions = stats_query.sum(:lines_added) || 0
    @total_deletions = stats_query.sum(:lines_removed) || 0
    @last_updated = @recent_commits.first&.commit_date || Time.current

    # Get contributions summary with user details and additional stats
    @contributions = @project.github_contributions(
      branch: @selected_branch,
      agreement_only: @agreement_only,
      agreement_user_ids: agreement_user_ids,
      user_name: @user_name
    )

    # Get available branches for the dropdown
    @available_branches = @project.available_branches
    @available_users = stats_query.pluck(:unregistered_user_name).compact.uniq.sort

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
          },
          pagination: {
            current_page: @recent_commits.current_page,
            total_pages: @recent_commits.total_pages,
            per_page: @recent_commits.limit_value,
            total_count: @recent_commits.total_count
          }
        }
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
