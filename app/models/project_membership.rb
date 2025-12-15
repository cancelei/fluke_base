# frozen_string_literal: true

class ProjectMembership < ApplicationRecord
  # Role constants
  ROLES = %w[owner admin member guest].freeze
  ROLE_HIERARCHY = { "owner" => 4, "admin" => 3, "member" => 2, "guest" => 1 }.freeze

  # Associations
  belongs_to :project
  belongs_to :user
  belongs_to :invited_by, class_name: "User", optional: true

  # Validations
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :project_id, message: "already has a membership for this project" }

  # Scopes
  scope :owners, -> { where(role: "owner") }
  scope :admins, -> { where(role: %w[owner admin]) }
  scope :members, -> { where(role: %w[owner admin member]) }
  scope :guests, -> { where(role: "guest") }
  scope :active, -> { where.not(accepted_at: nil) }
  scope :pending, -> { where(accepted_at: nil) }

  # Role check methods
  def owner?
    role == "owner"
  end

  def admin?
    role.in?(%w[owner admin])
  end

  def member?
    role.in?(%w[owner admin member])
  end

  def guest?
    role == "guest"
  end

  # Role hierarchy methods
  def role_level
    ROLE_HIERARCHY[role] || 0
  end

  def can_manage_role?(target_role)
    role_level > ROLE_HIERARCHY[target_role.to_s]
  end

  def higher_role_than?(other_membership)
    return true if other_membership.nil?
    role_level > other_membership.role_level
  end

  # Status methods
  def accepted?
    accepted_at.present?
  end

  def pending?
    accepted_at.nil?
  end

  def accept!
    update!(accepted_at: Time.current)
  end

  # Class methods for role labels
  def self.role_options
    ROLES.map { |role| [ role.titleize, role ] }
  end

  def self.role_options_for(current_role)
    current_level = ROLE_HIERARCHY[current_role.to_s] || 0
    ROLES.select { |role| ROLE_HIERARCHY[role] < current_level }
         .map { |role| [ role.titleize, role ] }
  end

  def role_label
    role.titleize
  end
end
