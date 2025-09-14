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

  # Pay integration
  include Pay::Billable

  # Validations
  validates :github_token, length: { maximum: 255 }, allow_blank: true
  validates :github_username, format: { with: /\A[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}\z/i, message: "is not a valid GitHub username", allow_blank: true }
  validates :first_name, :last_name, presence: true

  # Relationships
  has_many :projects, dependent: :destroy
  has_many :time_logs

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
    # This method is used by the navbar and other views to get the currently selected project
    # The actual project selection is managed by ApplicationController#set_selected_project
    # which stores the project_id in the session
    nil # The actual project is set by the controller
  end

  def show_project_context_nav?
    # Returns the user's preference for showing the project context navigation
    # This column defaults to true, so users will see the nav by default
    self[:show_project_context_nav]
  end

  def accessible_projects
    # Return all projects the user has access to through ownership, agreements, or collaboration
    owned_projects = projects
    agreement_projects = (initiated_agreements.includes(:project).map(&:project) +
                         received_agreements.includes(:project).map(&:project)).compact

    (owned_projects + agreement_projects).uniq
  end
end
