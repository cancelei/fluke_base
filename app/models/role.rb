class Role < ApplicationRecord
  # Constants for role names
  ENTREPRENEUR = "Entrepreneur"
  MENTOR = "Mentor"
  CO_FOUNDER = "Co-Founder"

  # Relationships
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  before_save :standardize_name

  # Scopes for finding specific roles
  scope :entrepreneur, -> { find_by(name: ENTREPRENEUR) }
  scope :mentor, -> { find_by(name: MENTOR) }
  scope :co_founder, -> { find_by(name: CO_FOUNDER) }

  # Ensure default roles exist
  def self.ensure_default_roles_exist
    [ ENTREPRENEUR, MENTOR, CO_FOUNDER ].each do |role_name|
      Role.find_or_create_by!(name: role_name)
    end
  end

  private

  def standardize_name
    return unless name
    # Match role name with one of the constants if possible
    if name.downcase == ENTREPRENEUR.downcase
      self.name = ENTREPRENEUR
    elsif name.downcase == MENTOR.downcase
      self.name = MENTOR
    elsif name.downcase == CO_FOUNDER.downcase
      self.name = CO_FOUNDER
    end
  end
end
