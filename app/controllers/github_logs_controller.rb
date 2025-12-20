# frozen_string_literal: true

# Controller for displaying GitHub activity logs
#
# Refactored to use Github::LogsQuery, Github::StatisticsCalculator, and
# Github::ContributionsSummary for DRY service layer architecture.
#
class GithubLogsController < ApplicationController
  before_action :set_project
  before_action :authenticate_user!
  before_action :authorize_access!

  def index
    # Use LogsQuery for all filtering logic
    @logs_query = Github::LogsQuery.new(project: @project, params: filter_params)

    # Get filter values for view
    @selected_branch = @logs_query.selected_branch
    @agreement_only = @logs_query.agreement_only?
    @user_name = filter_params[:user_name]

    # Get paginated commits using the query object
    @recent_commits = @logs_query.recent_commits(page: params[:page])

    # Calculate statistics using the calculator service
    stats = Github::StatisticsCalculator.new(project: @project, query: @logs_query.stats_query)
    @total_commits = stats.total_commits
    @total_additions = stats.total_additions
    @total_deletions = stats.total_deletions
    @last_updated = stats.last_updated

    # Get contributions using the summary service
    @contributions = Github::ContributionsSummary.new(
      project: @project,
      branch: @selected_branch,
      agreement_only: @agreement_only,
      agreement_user_ids: @logs_query.agreement_user_ids,
      user_name: @user_name
    ).call

    # Get available filters
    @available_branches = @logs_query.available_branches
    @available_users = @logs_query.available_users

    respond_to do |format|
      format.html
      format.json { render_json_response }
    end
  end

  private

  def filter_params
    params.permit(:project_id, :branch, :agreement_only, :user_name)
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def authorize_access!
    unless @project.can_view_github_logs?(current_user)
      redirect_to @project,
                  alert: "You don't have permission to view GitHub logs for this project."
    end
  end

  def render_json_response
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
  end

  helper_method :current_branch

  def current_branch
    params[:branch].presence
  end
end
