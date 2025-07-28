class DashboardQuery
  def initialize(current_user)
    @current_user = current_user
  end

  def recent_projects(limit = 5)
    @current_user.projects.order(created_at: :desc).limit(limit)
  end

  def recent_agreements(limit = 5)
    @current_user.all_agreements.order(created_at: :desc).limit(limit)
  end

  def upcoming_meetings(limit = 3)
    Meeting.joins(agreement: :agreement_participants)
           .where(agreement_participants: { user_id: @current_user.id })
           .upcoming
           .limit(limit)
  end

  def mentor_opportunities
    return Project.none unless @current_user.has_role?(:mentor)

    # Find projects seeking mentors where user doesn't have an agreement
    Project.where("collaboration_type = ? OR collaboration_type = ?",
                  Project::SEEKING_MENTOR, Project::SEEKING_BOTH)
           .where.not(id: Agreement.joins(:agreement_participants)
                                    .where(agreement_participants: { user_id: @current_user.id })
                                    .select(:project_id))
           .limit(6)
  end

  def stats
    {
      total_projects: @current_user.projects.count,
      active_agreements: @current_user.all_agreements.where(status: Agreement::ACCEPTED).count,
      total_agreements: @current_user.all_agreements.count,
      other_party_agreements: Agreement.joins(:agreement_participants)
                                        .where(agreement_participants: { user_id: @current_user.id, is_initiator: false })
                                        .count,
      mentor_seeking_projects: mentor_seeking_projects_count
    }
  end

  private

  def mentor_seeking_projects_count
    Project.where("collaboration_type = ? OR collaboration_type = ?",
                  Project::SEEKING_MENTOR, Project::SEEKING_BOTH).count
  end
end
