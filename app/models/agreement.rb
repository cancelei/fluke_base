# == Schema Information
#
# Table name: agreements
#
#  id                :bigint           not null, primary key
#  agreement_type    :string           not null
#  end_date          :date             not null
#  equity_percentage :decimal(5, 2)
#  hourly_rate       :decimal(10, 2)
#  milestone_ids     :integer          default([]), is an Array
#  payment_type      :string           not null
#  start_date        :date             not null
#  status            :string           not null
#  tasks             :text             not null
#  terms             :text
#  weekly_hours      :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  project_id        :bigint           not null
#
# Indexes
#
#  index_agreements_on_agreement_type             (agreement_type)
#  index_agreements_on_created_at                 (created_at)
#  index_agreements_on_payment_type               (payment_type)
#  index_agreements_on_project_id                 (project_id)
#  index_agreements_on_status                     (status)
#  index_agreements_on_status_and_agreement_type  (status,agreement_type)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#

# Agreement model representing collaboration agreements between users.
#
# Agreements formalize working relationships on projects, supporting
# mentorship and co-founder arrangements with various payment types.
# Uses AASM state machine for status transitions.
#
# @example Creating a mentorship agreement
#   agreement = Agreement.create!(
#     project: project,
#     agreement_type: Agreement::MENTORSHIP,
#     payment_type: Agreement::HOURLY,
#     hourly_rate: 150,
#     start_date: Date.today,
#     end_date: 3.months.from_now,
#     tasks: 'Code reviews and architecture guidance'
#   )
#
# @example State transitions
#   agreement.accept!  # Pending -> Accepted
#   agreement.complete! # Accepted -> Completed
#
# == Agreement Types
# - +MENTORSHIP+ - One user mentors another on a project
# - +CO_FOUNDER+ - Users collaborate as co-founders
#
# == Payment Types
# - +HOURLY+ - Paid by hourly rate
# - +EQUITY+ - Compensated with equity percentage
# - +HYBRID+ - Combination of hourly and equity
#
# == Status Flow (AASM)
#   Pending -> Accepted -> Completed
#          -> Rejected
#          -> Cancelled
#          -> Countered (counter offer created)
#
# == Associations
# - +project+ - The project this agreement is for
# - +agreement_participants+ - Join table linking users to agreement
# - +meetings+ - Scheduled meetings between participants
# - +time_logs+ - Time tracked against this agreement
#
# @see AgreementParticipant
# @see Project
# @see TimeLog
class Agreement < ApplicationRecord
  include AASM

  MENTORSHIP = "Mentorship"
  CO_FOUNDER = "Co-Founder"

  PENDING = "Pending"
  ACCEPTED = "Accepted"
  COMPLETED = "Completed"
  REJECTED = "Rejected"
  CANCELLED = "Cancelled"
  COUNTERED = "Countered"

  HOURLY = "Hourly"
  EQUITY = "Equity"
  HYBRID = "Hybrid"

  # State machine for agreement status transitions
  aasm column: :status, whiny_transitions: false, no_direct_assignment: false do
    state :Pending, initial: true
    state :Accepted
    state :Rejected
    state :Completed
    state :Cancelled
    state :Countered

    event :accept_agreement do
      transitions from: :Pending, to: :Accepted
    end

    event :reject_agreement do
      transitions from: :Pending, to: :Rejected
    end

    event :complete_agreement do
      transitions from: :Accepted, to: :Completed
    end

    event :cancel_agreement do
      transitions from: :Pending, to: :Cancelled
    end

    event :counter_agreement do
      transitions from: :Pending, to: :Countered
    end
  end

  belongs_to :project
  has_many :agreement_participants, dependent: :destroy
  has_many :users, through: :agreement_participants

  has_many :meetings, dependent: :destroy

  has_many :github_logs, dependent: :destroy

  before_validation :init_agreement_type

  validates :project_id, presence: true
  validates :status, presence: true, inclusion: { in: [PENDING, ACCEPTED, REJECTED, COMPLETED, CANCELLED, COUNTERED] }
  validates :agreement_type, presence: true, inclusion: { in: [MENTORSHIP, CO_FOUNDER] }
  validates :payment_type, presence: true, inclusion: { in: [HOURLY, EQUITY, HYBRID] }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :tasks, presence: true
  validates :weekly_hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 40 }, if: -> { agreement_type == MENTORSHIP }
  validates :hourly_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { payment_type == HOURLY || payment_type == HYBRID }
  validates :equity_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, if: -> { payment_type == EQUITY || payment_type == HYBRID }
  validate :end_date_after_start_date
  validates :milestone_ids, presence: true, if: -> { agreement_type == MENTORSHIP }
  validate :valid_payment_terms
  validate :different_entrepreneur_and_mentor

  scope :mentorships, -> { where(agreement_type: MENTORSHIP) }
  scope :co_founding, -> { where(agreement_type: CO_FOUNDER) }
  scope :pending, -> { where(status: PENDING) }
  scope :active, -> { where(status: ACCEPTED) }
  scope :completed, -> { where(status: COMPLETED) }
  scope :rejected, -> { where(status: REJECTED) }
  scope :cancelled, -> { where(status: CANCELLED) }
  scope :countered, -> { where(status: COUNTERED) }

  scope :with_project_and_users, -> { includes(:project, agreement_participants: :user) }
  scope :with_meetings, -> { includes(:meetings) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :for_user, ->(user_id) { joins(:agreement_participants).where(agreement_participants: { user_id: }) }

  def init_agreement_type
    return if self.agreement_type.present?
    self.agreement_type = self.weekly_hours.present? ? MENTORSHIP : CO_FOUNDER
  end

  def milestone_ids
    read_attribute(:milestone_ids) || []
  end

  def milestone_ids=(value)
    write_attribute(:milestone_ids, value)
  end

  def selected_milestones
    project.milestones.where(id: milestone_ids)
  end

  def total_hours_logged(context_user = nil)
    calculations_service.total_hours_logged(context_user)
  end

  def current_time_log
    calculations_service.current_time_log
  end

  scope :not_rejected_or_cancelled, -> { where.not(status: [REJECTED, CANCELLED]) }

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  def initiator = agreement_participants.find_by(is_initiator: true)&.user
  def initiator_id = initiator&.id
  def other_party = agreement_participants.find_by(is_initiator: false)&.user
  def other_party_id = other_party&.id
  def participants = agreement_participants.includes(:user)
  def participant_for_user(user) = agreement_participants.find_by(user:)

  def user_can_accept_or_counter?(user)
    participant = participant_for_user(user)
    participant&.accept_or_counter_turn_id == user.id
  end

  def is_initiator?(user)
    agreement_participants.find_by(user_id: user.id)&.is_initiator?
  end

  def other_party_for(user)
    agreement_participants.where.not(user_id: user.id).first&.user
  end

  def whose_turn?
    turn_user_id = agreement_participants.take&.accept_or_counter_turn_id
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
    other_participant = agreement_participants.where.not(user_id: current_user.id).take
    pass_turn_to_user(other_participant.user) if other_participant
  end

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

  def active? = status == ACCEPTED
  def pending? = status == PENDING
  def completed? = status == COMPLETED
  def rejected? = status == REJECTED
  def cancelled? = status == CANCELLED
  def countered? = status == COUNTERED

  def accept! = status_service.accept!
  def reject! = status_service.reject!
  def complete! = status_service.complete!
  def cancel! = status_service.cancel!
  def counter_offer!(counter_agreement) = status_service.counter_offer!(counter_agreement)
  def payment_details = calculations_service.payment_details

  def can_view_full_project_details?(user)
    return true if initiator&.id == user.id
    return true if other_party&.id == user.id
    false
  end

  def calculate_total_cost = calculations_service.total_cost
  def duration_in_weeks = calculations_service.duration_in_weeks
  def is_counter_offer? = agreement_participants.any?(&:counter_agreement_id)
  def counter_to_id = agreement_participants.take&.counter_agreement_id

  def counter_to
    counter_agreement_id = counter_to_id
    Agreement.find_by(id: counter_agreement_id) if counter_agreement_id
  end

  def counter_offers
    Agreement.joins(:agreement_participants)
            .where(agreement_participants: { counter_agreement_id: id })
            .distinct
  end

  def has_counter_offers? = counter_offers.exists?
  def most_recent_counter_offer = counter_offers.order(created_at: :desc).first
  def latest_counter_offer = most_recent_counter_offer

  # Ransack configuration for search/filter functionality
  def self.ransackable_attributes(auth_object = nil)
    %w[status agreement_type payment_type start_date end_date project_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[project agreement_participants users]
  end

  private

  def status_service = @status_service ||= AgreementStatusService.new(self)
  def calculations_service = @calculations_service ||= AgreementCalculationsService.new(self)
end
