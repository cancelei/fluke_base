class User < ApplicationRecord
  belongs_to :selected_project, class_name: "Project", optional: true

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

  def show_project_context_nav?
    # Project context navigation is now always shown for all users
    # This method is kept for backwards compatibility but always returns true
    true
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
      project_memberships.where(role: role).includes(:project).map(&:project)
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
end
