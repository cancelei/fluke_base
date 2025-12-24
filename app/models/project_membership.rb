# frozen_string_literal: true

# == Schema Information
#
# Table name: project_memberships
#
#  id            :bigint           not null, primary key
#  accepted_at   :datetime
#  invited_at    :datetime
#  role          :string           default("member"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  invited_by_id :bigint
#  project_id    :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_project_memberships_on_invited_by_id           (invited_by_id)
#  index_project_memberships_on_project_id              (project_id)
#  index_project_memberships_on_project_id_and_user_id  (project_id,user_id) UNIQUE
#  index_project_memberships_on_user_id                 (user_id)
#  index_project_memberships_on_user_id_and_role        (user_id,role)
#
# Foreign Keys
#
#  fk_rails_...  (invited_by_id => users.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class ProjectMembership < ApplicationRecord
  # Role constants
  ROLES = %w[owner admin member guest].freeze
  ROLE_HIERARCHY = { "owner" => 4, "admin" => 3, "member" => 2, "guest" => 1 }.freeze

  belongs_to :project
  belongs_to :user
  belongs_to :invited_by, class_name: "User", optional: true

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :project_id, message: "already has a membership for this project" }

  scope :owners, -> { where(role: "owner") }
  scope :admins, -> { where(role: %w[owner admin]) }
  scope :members, -> { where(role: %w[owner admin member]) }
  scope :guests, -> { where(role: "guest") }
  scope :active, -> { where.not(accepted_at: nil) }
  scope :pending, -> { where(accepted_at: nil) }

  def owner? = role == "owner"
  def admin? = role.in?(%w[owner admin])
  def member? = role.in?(%w[owner admin member])
  def guest? = role == "guest"
  def role_level = ROLE_HIERARCHY[role] || 0
  def can_manage_role?(target_role) = role_level > ROLE_HIERARCHY[target_role.to_s]

  def higher_role_than?(other_membership)
    return true if other_membership.nil?
    role_level > other_membership.role_level
  end

  def accepted? = accepted_at.present?
  def pending? = accepted_at.nil?
  def accept! = update!(accepted_at: Time.current)
  def self.role_options = ROLES.map { |role| [role.titleize, role] }

  def self.role_options_for(current_role)
    current_level = ROLE_HIERARCHY[current_role.to_s] || 0
    ROLES.select { |role| ROLE_HIERARCHY[role] < current_level }
         .map { |role| [role.titleize, role] }
  end

  def role_label = role.titleize
end
