# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  protected

  # Helper methods for common authorization patterns
  def admin?
    user&.admin?
  end

  def signed_in?
    user.present?
  end

  def owner?
    return false unless signed_in?
    return record == user if record.is_a?(User)
    return false unless record.respond_to?(:user_id)
    record.user_id == user.id
  end

  def admin_or_owner?
    admin? || owner?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
