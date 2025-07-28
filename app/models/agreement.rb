class Agreement < ApplicationRecord
  # Constants
  MENTORSHIP = "Mentorship"
  CO_FOUNDER = "Co-Founder"

  # Agreement statuses
  PENDING = "Pending"
  ACCEPTED = "Accepted"
  COMPLETED = "Completed"
  REJECTED = "Rejected"
  CANCELLED = "Cancelled"
  COUNTERED = "Countered"  # New status for counter offers

  # Payment types
  HOURLY = "Hourly"
  EQUITY = "Equity"
  HYBRID = "Hybrid"
  # enum :status, { pending: "Pending",
  #   accepted: "Accepted",
  #   completed: "Completed",
  #   rejected: "Rejected",
  #   cancelled: "Cancelled",
  #   countered: "Countered" }
  # Relationships
  belongs_to :project
  has_many :agreement_participants, dependent: :destroy
  has_many :users, through: :agreement_participants

  has_many :meetings, dependent: :destroy

  has_many :github_logs, dependent: :destroy

  before_validation :init_status, :init_agreement_type


  # Validations
  validates :project_id, presence: true
  validates :status, presence: true, inclusion: { in: [ PENDING, ACCEPTED, REJECTED, COMPLETED, CANCELLED, COUNTERED ] }
  validates :agreement_type, presence: true, inclusion: { in: [ MENTORSHIP, CO_FOUNDER ] }
  validates :payment_type, presence: true, inclusion: { in: [ HOURLY, EQUITY, HYBRID ] }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :tasks, presence: true
  validates :weekly_hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 40 }
  validates :hourly_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { payment_type == HOURLY || payment_type == HYBRID }
  validates :equity_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, if: -> { payment_type == EQUITY || payment_type == HYBRID }
  validate :end_date_after_start_date
  validates :milestone_ids, presence: true, if: -> { agreement_type == MENTORSHIP }
  validate :valid_payment_terms
  validate :different_entrepreneur_and_mentor

  # Scopes
  scope :mentorships, -> { where(agreement_type: MENTORSHIP) }
  scope :co_founding, -> { where(agreement_type: CO_FOUNDER) }
  scope :pending, -> { where(status: PENDING) }
  scope :active, -> { where(status: ACCEPTED) }
  scope :completed, -> { where(status: COMPLETED) }
  scope :rejected, -> { where(status: REJECTED) }
  scope :cancelled, -> { where(status: CANCELLED) }
  scope :countered, -> { where(status: COUNTERED) }

  def init_status
    self.status = PENDING if self.status.blank?
  end

  def init_agreement_type
    self.agreement_type = self.weekly_hours.present? ? MENTORSHIP : CO_FOUNDER
  end



  # Milestone methods
  def milestone_ids
    read_attribute(:milestone_ids) || []
  end

  def milestone_ids=(value)
    write_attribute(:milestone_ids, value)
  end

  def selected_milestones
    project.milestones.where(id: milestone_ids)
  end

  # Time tracking methods - delegated to calculations service
  def total_hours_logged
    calculations_service.total_hours_logged
  end

  def current_time_log
    calculations_service.current_time_log
  end

  scope :not_rejected_or_cancelled, -> { where.not(status: [ REJECTED, CANCELLED ]) }

  # Custom validation: ensure end date is after start date
  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  # Helper methods for compatibility with existing code
  def initiator
    agreement_participants.find_by(is_initiator: true)&.user
  end

  def initiator_id
    initiator&.id
  end

  def other_party
    agreement_participants.find_by(is_initiator: false)&.user
  end

  def other_party_id
    other_party&.id
  end

  def participants
    agreement_participants.includes(:user)
  end

  def participant_for_user(user)
    agreement_participants.find_by(user: user)
  end

  def user_can_accept_or_counter?(user)
    participant = participant_for_user(user)
    participant&.accept_or_counter_turn_id == user.id
  end

  # Turn-based system methods
  def whose_turn?
    # Find the participant whose turn it is to act
    turn_user_id = agreement_participants.first&.accept_or_counter_turn_id
    User.find_by(id: turn_user_id) if turn_user_id
  end

  def user_can_make_counter_offer?(user)
    participant = participant_for_user(user)
    participant&.can_make_counter_offer?
  end

  def user_can_accept?(user)
    participant = participant_for_user(user)
    participant&.can_accept_agreement?
  end

  def user_can_reject?(user)
    participant = participant_for_user(user)
    participant&.can_reject_agreement?
  end

  def pass_turn_to_user(user)
    agreement_participants.update_all(accept_or_counter_turn_id: user.id)
  end

  def pass_turn_to_other_party(current_user)
    other_participant = agreement_participants.where.not(user_id: current_user.id).first
    pass_turn_to_user(other_participant.user) if other_participant
  end

  # Custom validation: ensure entrepreneur and mentor are different users
  def different_entrepreneur_and_mentor
    participant_users = agreement_participants.map(&:user_id)
    if participant_users.uniq.length != participant_users.length
      errors.add(:base, "Entrepreneur and mentor cannot be the same person")
    end
  end

  def valid_payment_terms
    case payment_type
    when "Hourly"
      errors.add(:hourly_rate, "must be present for hourly payment") if hourly_rate.blank?
    when "Equity"
      errors.add(:equity_percentage, "must be present for equity payment") if equity_percentage.blank?
    end
  end

  # Status check methods
  def active?
    status == ACCEPTED
  end

  def pending?
    status == PENDING
  end

  def completed?
    status == COMPLETED
  end

  def rejected?
    status == REJECTED
  end

  def cancelled?
    status == CANCELLED
  end

  def countered?
    status == COUNTERED
  end

  # Returns the latest counter offer for this agreement
  def latest_counter_offer
    status_service.latest_counter_offer
  end

  # Status update methods - delegated to status service
  def accept!
    status_service.accept!
  end

  def reject!
    status_service.reject!
  end

  def complete!
    status_service.complete!
  end

  def cancel!
    status_service.cancel!
  end

  def counter_offer!(counter_agreement)
    status_service.counter_offer!(counter_agreement)
  end

  def payment_details
    calculations_service.payment_details
  end

  def can_view_full_project_details?(user)
    return true if initiator&.id == user.id
    return true if other_party&.id == user.id
    false
  end

  def calculate_total_cost
    calculations_service.total_cost
  end

  def duration_in_weeks
    calculations_service.duration_in_weeks
  end

  def has_counter_offers?
    status_service.has_counter_offers?
  end

  def most_recent_counter_offer
    status_service.most_recent_counter_offer
  end

  def is_counter_offer?
    # Check if this agreement is a counter offer by looking at agreement_participants
    agreement_participants.any?(&:counter_agreement_id)
  end

  def counter_to
    # Get the original agreement this is a counter offer to
    counter_agreement_id = agreement_participants.first&.counter_agreement_id
    Agreement.find_by(id: counter_agreement_id) if counter_agreement_id
  end

  def counter_offers
    # Get all agreements that are counter offers to this one
    Agreement.joins(:agreement_participants)
            .where(agreement_participants: { counter_agreement_id: id })
            .distinct
  end

  def has_counter_offers?
    counter_offers.exists?
  end

  def most_recent_counter_offer
    counter_offers.order(created_at: :desc).first
  end

  def latest_counter_offer
    most_recent_counter_offer
  end

  private

  def status_service
    @status_service ||= AgreementStatusService.new(self)
  end

  def calculations_service
    @calculations_service ||= AgreementCalculationsService.new(self)
  end
end
