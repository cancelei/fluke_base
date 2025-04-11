class ProjectPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can view their projects
  end

  def show?
    # Users can view projects they own or are associated with
    record.user == user || record.mentors.include?(user) || record.co_founders.include?(user)
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
