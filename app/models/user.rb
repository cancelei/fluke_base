class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Pay integration
  include Pay::Billable

  # Virtual attribute for role selection in forms
  attr_accessor :role_id

  # Relationships
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_many :projects, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Entrepreneur agreements
  has_many :entrepreneur_agreements, class_name: "Agreement",
           foreign_key: "entrepreneur_id", dependent: :destroy

  # Mentor agreements
  has_many :mentor_agreements, class_name: "Agreement",
           foreign_key: "mentor_id", dependent: :destroy

  # Messaging
  has_many :sent_conversations, class_name: "Conversation", foreign_key: "sender_id", dependent: :destroy
  has_many :received_conversations, class_name: "Conversation", foreign_key: "recipient_id", dependent: :destroy
  has_many :messages, dependent: :destroy

  # Validations
  validates :first_name, :last_name, presence: true

  # Scopes
  scope :with_role, ->(role_name) {
    joins(:roles).where(roles: { name: role_name })
  }

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def unread_notifications_count
    notifications.unread.count
  end

  def has_role?(role_name)
    # Normalize the role name to match one of our standard roles
    normalized_name = normalize_role_name(role_name)
    roles.exists?(name: normalized_name)
  end

  def add_role(role_name)
    # Normalize the role name to match one of our standard roles
    normalized_name = normalize_role_name(role_name)
    role = Role.find_or_create_by(name: normalized_name)
    user_roles.find_or_create_by(role: role)
    true
  end

  def remove_role(role_name)
    # Normalize the role name to match one of our standard roles
    normalized_name = normalize_role_name(role_name)
    role = Role.find_by(name: normalized_name)
    user_roles.where(role: role).destroy_all if role
  end

  def onboarded_for?(role_name)
    # Normalize the role name to match one of our standard roles
    normalized_name = normalize_role_name(role_name)
    role = Role.find_by(name: normalized_name)
    return false unless role
    user_roles.where(role: role, onboarded: true).exists?
  end

  def mark_onboarded_for(role_name)
    # Normalize the role name to match one of our standard roles
    normalized_name = normalize_role_name(role_name)
    role = Role.find_by(name: normalized_name)
    return false unless role
    user_role = user_roles.find_by(role: role)
    return false unless user_role
    user_role.update(onboarded: true)
  end

  def requires_onboarding?
    # Check if any role needs onboarding
    roles.any? do |role|
      !user_roles.find_by(role: role).onboarded
    end
  end

  def current_onboarding_path
    # Return the path for the first non-onboarded role
    entrepreneur_roles = [ Role::ENTREPRENEUR, Role::CO_FOUNDER ]
    mentor_role = Role::MENTOR

    # First check entrepreneur roles
    entrepreneur_roles.each do |role_name|
      if has_role?(role_name) && !onboarded_for?(role_name)
        return :entrepreneur
      end
    end

    # Then check mentor role
    if has_role?(mentor_role) && !onboarded_for?(mentor_role)
      return :mentor
    end

    # Default to nil if all roles onboarded
    nil
  end

  # Return all agreements (both as entrepreneur and mentor)
  def all_agreements
    Agreement.where("entrepreneur_id = ? OR mentor_id = ?", id, id)
  end

  private

  def normalize_role_name(role_name)
    role_name = role_name.to_s

    # Check if matches one of our standard role names
    if role_name.downcase == Role::ENTREPRENEUR.downcase
      Role::ENTREPRENEUR
    elsif role_name.downcase == Role::MENTOR.downcase
      Role::MENTOR
    elsif role_name.downcase == Role::CO_FOUNDER.downcase
      Role::CO_FOUNDER
    else
      role_name
    end
  end
end
