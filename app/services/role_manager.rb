class RoleManager
  attr_reader :user

  def initialize(user)
    @user = user
  end

  # Add a role to the user if they meet the requirements
  def add_role(role_name)
    case role_name
    when Role::ENTREPRENEUR
      # Anyone can become an entrepreneur
      add_entrepreneur_role
    when Role::MENTOR
      # To become a mentor, a user must be an entrepreneur with at least one completed project
      add_mentor_role
    when Role::CO_FOUNDER
      # To become a co-founder, a user must be in a mentor relationship
      add_co_founder_role
    else
      false
    end
  end

  # Check if a user is eligible for a specific role
  def eligible_for_role?(role_name)
    case role_name
    when Role::ENTREPRENEUR
      true # Anyone can be an entrepreneur
    when Role::MENTOR
      eligible_for_mentor_role?
    when Role::CO_FOUNDER
      eligible_for_co_founder_role?
    else
      false
    end
  end

  private

  def add_entrepreneur_role
    user.add_role(Role::ENTREPRENEUR)
  end

  def add_mentor_role
    return false unless eligible_for_mentor_role?
    user.add_role(Role::MENTOR)
  end

  def add_co_founder_role
    return false unless eligible_for_co_founder_role?
    user.add_role(Role::CO_FOUNDER)
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
                                 .where(status: Agreement::ACTIVE, agreement_type: Agreement::MENTORSHIP)
                                 .where("created_at <= ?", three_months_ago)
                                 .count

    active_long_mentorships > 0
  end
end
