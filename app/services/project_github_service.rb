# frozen_string_literal: true

# Service for GitHub integration queries for a project
# Query service - returns direct values
class ProjectGithubService < ApplicationService
  def initialize(project)
    @project = project
  end

  def connected?
    @project.repository_url.present?
  end

  def available_branches
    @project.github_branches.pluck(:id, :branch_name).compact.sort
  end

  def recent_logs(limit = 20)
    @project.github_logs.includes(:user).order(commit_date: :desc).limit(limit)
  end

  def contributions_summary(branch = nil)
    # Get registered users (those who have accounts)
    registered_query = @project.github_logs.joins(:user, :github_branch_logs).where.not(users: { id: nil })
    unregistered_query = @project.github_logs.joins(:github_branch_logs).where(user_id: nil).where.not(unregistered_user_name: [nil, ""])

    if branch.present?
      registered_query = registered_query.where(github_branch_logs: { github_branch_id: branch })
      unregistered_query = unregistered_query.where(github_branch_logs: { github_branch_id: branch })
    end

    # Get registered user contributions
    registered_contributions = registered_query
      .select("users.id as user_id, users.first_name, users.last_name, users.github_username,
               COUNT(github_logs.id) as commit_count,
               SUM(github_logs.lines_added) as total_added,
               SUM(github_logs.lines_removed) as total_removed,
               MIN(github_logs.commit_date) as first_commit_date,
               MAX(github_logs.commit_date) as last_commit_date")
      .group("users.id, users.first_name, users.last_name, users.github_username")

    # Get unregistered user contributions
    unregistered_contributions = unregistered_query
      .select("NULL as user_id, github_logs.unregistered_user_name,
               COUNT(github_logs.id) as commit_count,
               SUM(github_logs.lines_added) as total_added,
               SUM(github_logs.lines_removed) as total_removed,
               MIN(github_logs.commit_date) as first_commit_date,
               MAX(github_logs.commit_date) as last_commit_date")
      .group("github_logs.unregistered_user_name")

    # Combine results
    all_contributions = registered_contributions.to_a + unregistered_contributions.to_a
    all_contributions.sort_by { |c| -c.commit_count.to_i }
  end

  def contributions_summary_basic
    @project.github_contributions
  end

  def can_view_logs?(user)
    # Project owner can always view logs
    return true if @project.user == user

    # Users with active agreements can view logs
    @project.agreements.active.joins(:agreement_participants)
            .exists?(agreement_participants: { user_id: user.id })
  end

  def can_access_repository?(user)
    # Same logic as can_view_logs for now
    can_view_logs?(user)
  end
end
