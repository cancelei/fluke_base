class ProjectPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can view their projects
  end

  def show?
    true # All authenticated users can view any project
  end

  def create?
    # Only entrepreneurs and co-founders can create projects
    user.has_role?(Role::ENTREPRENEUR)
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
    true # All authenticated users can explore projects
  end

  class Scope < Scope
    def resolve
      scope.all # All authenticated users can see all projects
    end
  end
end
