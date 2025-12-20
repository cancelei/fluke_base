class DashboardQuery
  def initialize(current_user)
    @current_user = current_user
  end

  # Returns user's owned projects ordered by creation date (original behavior)
  def recent_projects(limit = 5)
    @current_user.projects.order(created_at: :desc).limit(limit)
  end

  # Returns ALL accessible projects (owned + agreements) ordered by GitHub activity
  # Projects with recent commits appear first, then by last update
  def projects_by_activity(limit = 5)
    accessible_project_ids = @current_user.accessible_projects.map(&:id)
    return Project.none if accessible_project_ids.empty?

    # Use a subquery to get last commit date for ordering
    # We need to use a subquery approach to avoid issues with count
    last_commits = GithubLog.select("project_id, MAX(commit_date) as last_commit_at")
                            .where(project_id: accessible_project_ids)
                            .group(:project_id)

    Project.where(id: accessible_project_ids)
           .joins("LEFT JOIN (#{last_commits.to_sql}) AS lc ON lc.project_id = projects.id")
           .order(Arel.sql("lc.last_commit_at DESC NULLS LAST, projects.updated_at DESC"))
           .limit(limit)
  end

  # Returns recent commits across ALL accessible projects
  def recent_activity(limit = 10)
    accessible_project_ids = @current_user.accessible_projects.map(&:id)
    return GithubLog.none if accessible_project_ids.empty?

    GithubLog.where(project_id: accessible_project_ids)
             .includes(:project, :user)
             .order(commit_date: :desc)
             .limit(limit)
  end

  # Returns activity summary stats across all accessible projects
  def activity_summary
    projects = @current_user.accessible_projects
    return empty_activity_summary if projects.empty?

    project_ids = projects.map(&:id)

    {
      total_projects: projects.count,
      projects_with_repos: projects.count(&:github_connected?),
      total_commits_this_week: GithubLog.where(project_id: project_ids)
                                        .where("commit_date > ?", 7.days.ago)
                                        .count,
      total_commits_this_month: GithubLog.where(project_id: project_ids)
                                         .where("commit_date > ?", 30.days.ago)
                                         .count,
      active_projects: projects.count { |p| p.activity_level == :active },
      moderate_projects: projects.count { |p| p.activity_level == :moderate },
      stale_projects: projects.count { |p| p.activity_level == :stale }
    }
  end

  def recent_agreements(limit = 5)
    @current_user.all_agreements
                 .includes(:project, agreement_participants: :user)
                 .order(created_at: :desc)
                 .limit(limit)
  end

  def upcoming_meetings(limit = 3)
    Meeting.joins(agreement: :agreement_participants)
           .includes(agreement: { agreement_participants: :user })
           .where(agreement_participants: { user_id: @current_user.id })
           .upcoming
           .limit(limit)
  end

  def mentor_opportunities
    # Find projects seeking mentors where user doesn't have an agreement
    Project.includes(:user)
           .where("collaboration_type = ? OR collaboration_type = ?",
                  Project::SEEKING_MENTOR, Project::SEEKING_BOTH)
           .where.not(id: Agreement.joins(:agreement_participants)
                                    .where(agreement_participants: { user_id: @current_user.id })
                                    .select(:project_id))
           .limit(6)
  end

  def stats
    dashboard_stat = DashboardStat.for_user(@current_user)

    # If no stats or they're stale, refresh the materialized view
    if dashboard_stat.nil? || dashboard_stat.stale?
      DashboardStat.refresh!
      dashboard_stat = DashboardStat.for_user(@current_user)
    end

    return default_stats if dashboard_stat.nil?

    {
      total_projects: dashboard_stat.total_projects,
      active_agreements: dashboard_stat.active_agreements,
      total_agreements: dashboard_stat.total_agreements,
      completed_agreements: dashboard_stat.completed_agreements,
      pending_agreements: dashboard_stat.pending_agreements,
      agreements_as_initiator: dashboard_stat.agreements_as_initiator,
      agreements_as_participant: dashboard_stat.agreements_as_participant,
      total_meetings: dashboard_stat.total_meetings,
      upcoming_meetings: dashboard_stat.upcoming_meetings,
      total_milestones: dashboard_stat.total_milestones,
      completed_milestones: dashboard_stat.completed_milestones,
      in_progress_milestones: dashboard_stat.in_progress_milestones,
      projects_seeking_mentor: dashboard_stat.projects_seeking_mentor,
      projects_seeking_cofounder: dashboard_stat.projects_seeking_cofounder
    }
  end

  private

  def empty_activity_summary
    {
      total_projects: 0,
      projects_with_repos: 0,
      total_commits_this_week: 0,
      total_commits_this_month: 0,
      active_projects: 0,
      moderate_projects: 0,
      stale_projects: 0
    }
  end

  def default_stats
    {
      total_projects: 0,
      active_agreements: 0,
      total_agreements: 0,
      completed_agreements: 0,
      pending_agreements: 0,
      agreements_as_initiator: 0,
      agreements_as_participant: 0,
      total_meetings: 0,
      upcoming_meetings: 0,
      total_milestones: 0,
      completed_milestones: 0,
      in_progress_milestones: 0,
      projects_seeking_mentor: 0,
      projects_seeking_cofounder: 0
    }
  end

  def mentor_seeking_projects_count
    Project.where("collaboration_type = ? OR collaboration_type = ?",
                  Project::SEEKING_MENTOR, Project::SEEKING_BOTH).count
  end
end
