class User < ApplicationRecord
  belongs_to :selected_project, class_name: "Project", optional: true
  belongs_to :current_role, class_name: "Role", optional: true

  include Roleable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Pay integration
  include Pay::Billable

  # Validations
  validates :github_token, length: { maximum: 255 }, allow_blank: true

  # Virtual attribute for role selection in forms
  attr_accessor :role_id

  # Relationships
  has_many :projects, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # All agreements where user is a party
  has_many :initiated_agreements, class_name: "Agreement",
           foreign_key: "initiator_id", dependent: :destroy
  has_many :received_agreements, class_name: "Agreement",
           foreign_key: "other_party_id", dependent: :destroy

  # Agreements where user is the entrepreneur (project owner)
  def my_agreements
    Agreement.joins(:project)
            .where("projects.user_id = ?", id)
  end

  # Agreements where user is the mentor/co-founder (not project owner)
  def other_party_agreements
    Agreement.joins(:project)
            .where("(agreements.initiator_id = ? OR agreements.other_party_id = ?) AND projects.user_id != ?",
                  id, id, id)
  end

  # Alias for clarity when user is a mentor
  def agreements_as_mentor
    other_party_agreements
  end

  # Alias for clarity when user is an entrepreneur
  def agreements_as_entrepreneur
    my_agreements
  end

  # Validations
  validates :github_username, format: { with: /^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$/i, message: 'is not a valid GitHub username', allow_blank: true, multiline: true }

  # Class methods
  def self.find_by_github_identifier(identifier)
    return nil if identifier.blank?
    
    # Try to find by GitHub username (case insensitive)
    user = where('LOWER(github_username) = ?', identifier.downcase).first
    return user if user
    
    # Try to find by email
    find_by(email: identifier.downcase)
  end

  # Messaging
  has_many :sent_conversations, class_name: "Conversation", foreign_key: "sender_id", dependent: :destroy
  has_many :received_conversations, class_name: "Conversation", foreign_key: "recipient_id", dependent: :destroy
  has_many :messages, dependent: :destroy

  # Avatar
  has_one_attached :avatar

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

  def all_agreements
    Agreement.where("initiator_id = ? OR other_party_id = ?", id, id)
  end

  def avatar_url
    if avatar.attached?
      avatar
    else
      # Generate initials avatar and convert to base64 data URL
      initials = "#{first_name&.first}#{last_name&.first}".upcase
      color = Digest::MD5.hexdigest(initials)[0..5]
      svg = <<~SVG
        <svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
          <rect width="200" height="200" fill="##{color}"/>
          <text x="50%" y="50%" font-family="Arial" font-size="80" fill="white" text-anchor="middle" dominant-baseline="middle">#{initials}</text>
        </svg>
      SVG
      "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
    end
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  def selected_project
    # This method is used by the navbar and other views to get the currently selected project
    # The actual project selection is managed by ApplicationController#set_selected_project
    # which stores the project_id in the session
    nil # The actual project is set by the controller
  end
end
