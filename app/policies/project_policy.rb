class ProjectPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can view their projects
  end

  def show?
    # Users can view projects they own
    return true if record.user == user

    # Users with active agreements can view full project details
    if record.agreements.exists?([
      "(entrepreneur_id = :user_id OR mentor_id = :user_id) AND status = :status",
      { user_id: user.id, status: Agreement::ACTIVE }
    ])
      return true
    end

    # Mentors can view basic project info if they have a pending agreement
    if user.has_role?(:mentor) && record.agreements.exists?([
      "mentor_id = :user_id AND status = :status",
      { user_id: user.id, status: Agreement::PENDING }
    ])
      return true
    end

    # Mentors can view basic project info if the project is seeking a mentor
    if user.has_role?(:mentor) && record.seeking_mentor?
      return true
    end

    false
  end

  def create?
    # Only entrepreneurs and co-founders can create projects
    user.has_role?(Role::ENTREPRENEUR) || user.has_role?(Role::CO_FOUNDER)
  end

  def update?
    # Only project owners can update projects
    record.user == user
  end

  def destroy?
    # Only project owners can delete projects
    record.user == user
  end

  def explore?
    # Only mentors can explore available projects
    user.has_role?(Role::MENTOR)
  end

  class Scope < Scope
    def resolve
      if user.has_role?(Role::MENTOR)
        # Mentors can see all projects
        scope.all
      else
        # Others can only see their own projects
        scope.where(user: user)
      end
    end
  end
end
