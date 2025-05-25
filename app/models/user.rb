class User < ApplicationRecord
  belongs_to :selected_project, class_name: "Project", optional: true

  include Roleable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Pay integration
  include Pay::Billable

  # Virtual attribute for role selection in forms
  attr_accessor :role_id

  # Relationships
  has_many :projects, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Entrepreneur agreements
  has_many :my_agreements, class_name: "Agreement",
           foreign_key: "initiator_id", dependent: :destroy

  # Mentor agreements
  has_many :other_party_agreements, class_name: "Agreement",
           foreign_key: "other_party_id", dependent: :destroy

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
