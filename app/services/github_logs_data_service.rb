# frozen_string_literal: true

# Service for loading GitHub logs data for Turbo Stream updates
# Used when switching projects in the context nav to update page content
class GithubLogsDataService < ApplicationService
  def initialize(project, user, params = {})
    @project = project
    @user = user
    @params = params
  end

  def call
    return failure_result(:not_found, "Project not found") unless @project

    Success(build_data)
  end

  private

  def build_data
    {
      stats_locals: stats_data,
      contributions_locals: contributions_data,
      commits_locals: commits_data,
      header_locals: header_data
    }
  end

  def stats_data
    {
      total_commits: stats_query.count,
      total_additions: stats_query.sum(:lines_added) || 0,
      total_deletions: stats_query.sum(:lines_removed) || 0,
      last_updated: recent_commits.first&.commit_date || Time.current,
      project: @project
    }
  end

  def contributions_data
    {
      contributions: @project.github_contributions(
        branch: selected_branch,
        agreement_only: agreement_only?,
        agreement_user_ids:
      ),
      last_updated: recent_commits.first&.commit_date || Time.current,
      project: @project
    }
  end

  def commits_data
    {
      recent_commits:,
      project: @project
    }
  end

  def header_data
    {
      project: @project,
      available_branches: @project.available_branches,
      selected_branch:,
      agreement_only: agreement_only?
    }
  end

  def recent_commits
    @recent_commits ||= begin
      query = @project.github_logs.includes(:user, :github_branch_logs).order(commit_date: :desc)
      query = query.where(github_branch_logs: { github_branch_id: selected_branch }) if selected_branch.present? && selected_branch.to_i != 0
      query = query.where(user_id: agreement_user_ids) if agreement_only?
      query.page(1).per(15)
    end
  end

  def stats_query
    @stats_query ||= begin
      query = @project.github_logs
      query = query.joins(:github_branch_logs).where(github_branch_logs: { github_branch_id: selected_branch }) if selected_branch.present? && selected_branch.to_i != 0
      query = query.where(user_id: agreement_user_ids) if agreement_only?
      query.distinct
    end
  end

  def selected_branch
    @params[:branch].presence
  end

  def agreement_only?
    @params[:agreement_only].present?
  end

  def agreement_user_ids
    return nil unless agreement_only?

    @agreement_user_ids ||= begin
      @project.mentorships
              .where(status: "Accepted")
              .joins(:agreement_participants)
              .pluck("agreement_participants.user_id")
              .flatten.uniq
    end
  end
end
