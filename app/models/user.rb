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
  has_many :entrepreneur_agreements, class_name: "Agreement",
           foreign_key: "entrepreneur_id", dependent: :destroy

  # Mentor agreements
  has_many :mentor_agreements, class_name: "Agreement",
           foreign_key: "mentor_id", dependent: :destroy

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
    Agreement.where("entrepreneur_id = ? OR mentor_id = ?", id, id)
  end

  def avatar_url
    if avatar.attached?
      avatar
    else
      # Generate initials avatar and convert to base64 data URL
      avatar = LetterAvatar.generate("#{first_name} #{last_name}", 200)
      "data:image/png;base64,#{Base64.strict_encode64(File.read(avatar))}"
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
