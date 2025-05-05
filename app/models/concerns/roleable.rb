module Roleable
  extend ActiveSupport::Concern

  included do
    has_many :user_roles, dependent: :destroy
    has_many :roles, through: :user_roles
  end

  def has_role?(role_name)
    roles.exists?(name: normalize_role_name(role_name))
  end

  def add_role(role_name)
    normalized_name = normalize_role_name(role_name)
    return false unless Role.exists?(name: normalized_name)
    roles << Role.find_by(name: normalized_name) unless has_role?(normalized_name)
  end

  def remove_role(role_name)
    normalized_name = normalize_role_name(role_name)
    role = Role.find_by(name: normalized_name)
    user_roles.where(role: role).destroy_all if role
  end

  def onboarded_for?(role_name)
    normalized_name = normalize_role_name(role_name)
    role = Role.find_by(name: normalized_name)
    return false unless role
    user_roles.where(role: role, onboarded: true).exists?
  end

  def mark_onboarded_for(role_name)
    normalized_name = normalize_role_name(role_name)
    role = Role.find_by(name: normalized_name)
    return false unless role
    user_role = user_roles.find_by(role: role)
    return false unless user_role
    user_role.update(onboarded: true)
  end

  def requires_onboarding?
    roles.any? { |role| !user_roles.find_by(role: role).onboarded }
  end

  def current_onboarding_path
    # Return the path for the first non-onboarded role
    entrepreneur_roles = [ Role::ENTREPRENEUR, Role::CO_FOUNDER ]
    mentor_role = Role::MENTOR

    # First check entrepreneur roles
    entrepreneur_roles.each do |role_name|
      return :entrepreneur if has_role?(role_name) && !onboarded_for?(role_name)
    end

    # Then check mentor role
    return :mentor if has_role?(mentor_role) && !onboarded_for?(mentor_role)

    nil
  end

  def onboarding_path_for_role(role_name)
    case role_name
    when Role::ENTREPRENEUR, Role::CO_FOUNDER
      :entrepreneur
    when Role::MENTOR
      :mentor
    else
      nil
    end
  end

  private

  def normalize_role_name(role_name)
    case role_name.to_s.downcase
    when "entrepreneur", "founder"
      Role::ENTREPRENEUR
    when "mentor", "advisor"
      Role::MENTOR
    when "co-founder", "cofounder"
      Role::CO_FOUNDER
    else
      role_name.to_s
    end
  end
end
