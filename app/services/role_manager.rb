class RoleManager
  attr_reader :user

  def initialize(user)
    @user = user
  end

  # Add a role to the user if they meet the requirements
  def add_role(role_name)
    return false unless eligible_for_role?(role_name)
    @user.add_role(role_name)
  end

  # Check if a user is eligible for a specific role
  def eligible_for_role?(role_name)
    case role_name
    when Role::ENTREPRENEUR
      eligible_for_entrepreneur_role?
    when Role::MENTOR
      eligible_for_mentor_role?
    when Role::CO_FOUNDER
      eligible_for_co_founder_role?
    else
      false
    end
  end

  def onboarding_path_for_role(role_name)
    case role_name
    when Role::ENTREPRENEUR, Role::CO_FOUNDER
      onboarding_entrepreneur_path
    when Role::MENTOR
      onboarding_mentor_path
    else
      dashboard_path
    end
  end

  private

  def eligible_for_entrepreneur_role?
    # Anyone can be an entrepreneur
    true
  end

  def eligible_for_mentor_role?
    # Eligible if:
    # 1. User is an entrepreneur
    # 2. Has at least one project that's been active for more than 6 months
    # OR has completed a project
    return false unless user.has_role?(Role::ENTREPRENEUR)

    six_months_ago = 6.months.ago.to_date

    completed_projects = user.projects.joins(:milestones)
                            .where(milestones: { status: Milestone::COMPLETED })
                            .distinct.count

    long_running_projects = user.projects
                               .where("created_at <= ?", six_months_ago)
                               .count

    completed_projects > 0 || long_running_projects > 0
  end

  def eligible_for_co_founder_role?
    # Eligible if:
    # 1. User is a mentor
    # 2. Has at least one active mentorship agreement that's been active for more than 3 months
    return false unless user.has_role?(Role::MENTOR)

    three_months_ago = 3.months.ago.to_date

    active_long_mentorships = user.mentor_agreements
                                 .where(status: Agreement::ACCEPTED, agreement_type: Agreement::MENTORSHIP)
                                 .where("created_at <= ?", three_months_ago)
                                 .count

    active_long_mentorships > 0
  end
end
