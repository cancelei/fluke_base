# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  admin                    :boolean          default(FALSE), not null
#  avatar                   :string
#  bio                      :text
#  business_info            :text
#  business_stage           :string
#  email                    :string           default(""), not null
#  encrypted_password       :string           default(""), not null
#  facebook                 :string
#  first_name               :string           not null
#  github_token             :string(255)
#  github_username          :string
#  help_seekings            :string           default([]), is an Array
#  hourly_rate              :float
#  industries               :string           default([]), is an Array
#  instagram                :string
#  last_name                :string           not null
#  linkedin                 :string
#  multi_project_tracking   :boolean          default(FALSE), not null
#  remember_created_at      :datetime
#  reset_password_sent_at   :datetime
#  reset_password_token     :string
#  show_project_context_nav :boolean          default(FALSE), not null
#  skills                   :string           default([]), is an Array
#  slug                     :string
#  theme_preference         :string           default("nord"), not null
#  tiktok                   :string
#  x                        :string
#  years_of_experience      :float
#  youtube                  :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  selected_project_id      :bigint
#
# Indexes
#
#  index_users_on_admin                 (admin)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_selected_project_id   (selected_project_id)
#  index_users_on_slug                  (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (selected_project_id => projects.id) ON DELETE => nullify
#
class User < ApplicationRecord
  extend FriendlyId

  belongs_to :selected_project, class_name: "Project", optional: true

  friendly_id :slug_candidates, use: [:slugged, :finders]

  # Define agreement_participants association before UserAgreements concern
  # This must be defined before any has_many :through associations that use it
  has_many :agreement_participants, dependent: :delete_all

  # Define initiated and received agreements explicitly here instead of in the concern
  has_many :initiated_agreements, -> { where(agreement_participants: { is_initiator: true }) },
           through: :agreement_participants, source: :agreement
  has_many :received_agreements, -> { where(agreement_participants: { is_initiator: false }) },
           through: :agreement_participants, source: :agreement

  # Now include concerns after all base associations are defined
  include UserAgreements
  include UserMessaging

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Available DaisyUI themes
  AVAILABLE_THEMES = %w[
    light nord cupcake emerald corporate
    dark night dracula forest business
  ].freeze

  DEFAULT_THEME = "nord".freeze

  # Pay integration
  include Pay::Billable

  # Validations
  validates :github_token, length: { maximum: 255 }, allow_blank: true
  validates :github_username, format: { with: /\A[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}\z/i, message: "is not a valid GitHub username", allow_blank: true }
  validates :first_name, :last_name, presence: true
  validates :theme_preference, inclusion: { in: AVAILABLE_THEMES }

  # Relationships
  has_many :projects, dependent: :destroy
  has_many :time_logs

  # Membership associations for tiered access control
  has_many :project_memberships, dependent: :destroy
  has_many :member_projects, through: :project_memberships, source: :project
  has_many :invitations_sent, class_name: "ProjectMembership", foreign_key: :invited_by_id

  # Avatar
  has_one_attached :avatar

  # Ratings - as rateable (receiving ratings) and rater (giving ratings)
  has_many :received_ratings, class_name: "Rating", as: :rateable, dependent: :destroy
  has_many :given_ratings, class_name: "Rating", foreign_key: :rater_id, dependent: :destroy, inverse_of: :rater

  # Class methods
  def self.find_by_github_identifier(identifier)
    return nil if identifier.blank?

    # Try to find by GitHub username (case insensitive)
    user = where("LOWER(github_username) = ?", identifier.downcase).first
    return user if user

    # Try to find by email
    find_by(email: identifier.downcase)
  end

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def avatar_url
    @avatar_service ||= AvatarService.new(self)
    @avatar_service.url
  end

  def initials
    @avatar_service ||= AvatarService.new(self)
    @avatar_service.initials
  end

  def selected_project
    # Delegate to ActiveRecord association; controller may still set session for convenience
    super
  end

  def accessible_projects
    # Return all projects the user has access to through ownership or active agreements
    owned_projects = projects
    # Only include projects from Accepted or Completed agreements
    active_statuses = %w[Accepted Completed]
    agreement_projects = (
      initiated_agreements.where(status: active_statuses).includes(:project).map(&:project) +
      received_agreements.where(status: active_statuses).includes(:project).map(&:project)
    ).compact

    (owned_projects + agreement_projects).uniq
  end

  # Membership helper methods
  def projects_with_role(role = nil)
    if role
      project_memberships.where(role:).includes(:project).map(&:project)
    else
      project_memberships.includes(:project).map(&:project)
    end
  end

  def role_in_project(project)
    project.effective_role_for(self)
  end

  def can_access_project?(project)
    project.user_has_access?(self)
  end

  def admin_projects
    project_memberships.admins.includes(:project).map(&:project)
  end

  # Rating helper methods
  def average_rating
    received_ratings.average_rating
  end

  def rating_count
    received_ratings.count
  end

  def rating_breakdown
    received_ratings.rating_breakdown
  end

  def rating_from(user)
    received_ratings.find_by(rater: user)
  end

  def rated_by?(user)
    received_ratings.exists?(rater: user)
  end

  def rate!(rater:, value:, review: nil)
    rating = received_ratings.find_or_initialize_by(rater:)
    rating.update!(value:, review:)
    rating
  end

  def update_rating_cache!
    # Optional: If you want to cache the average rating on the user record
    # This would require adding cached_average_rating column
    # update_column(:cached_average_rating, average_rating)
    true
  end

  # Ransack configuration for search/filter functionality
  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name bio email github_username created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[projects agreement_participants]
  end

  # FriendlyId: slug candidates for user URLs
  def slug_candidates
    [
      [:first_name, :last_name],
      [:first_name, :last_name, :id]
    ]
  end

  # FriendlyId: regenerate slug when name changes
  def should_generate_new_friendly_id?
    first_name_changed? || last_name_changed? || slug.blank?
  end
end
