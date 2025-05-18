class RoleManager
  include Rails.application.routes.url_helpers
  attr_reader :user

  def initialize(user)
    @user = user
  end

  # Add a role to the user if they meet the requirements
  def add_role(role_name)
    return false unless eligible_for_role?(role_name)
    user.add_role(role_name)
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
      Rails.application.routes.url_helpers.onboarding_entrepreneur_path
    when Role::MENTOR
      Rails.application.routes.url_helpers.onboarding_mentor_path
    else
      Rails.application.routes.url_helpers.dashboard_path
    end
  end

  private

  def eligible_for_entrepreneur_role?
    true # Anyone can be an entrepreneur
  end

  def eligible_for_mentor_role?
    true # Anyone can be a mentor
  end

  def eligible_for_co_founder_role?
    true # Anyone can be a co-founder
  end
end
