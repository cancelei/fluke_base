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

  # Relationships
  belongs_to :project
  belongs_to :entrepreneur, class_name: "User", foreign_key: "entrepreneur_id"
  belongs_to :mentor, class_name: "User", foreign_key: "mentor_id"
  has_many :meetings, dependent: :destroy
  belongs_to :counter_to, class_name: "Agreement", foreign_key: "counter_to_id", optional: true
  has_many :counter_offers, class_name: "Agreement", foreign_key: "counter_to_id", dependent: :destroy

  # Validations
  validates :project_id, presence: true
  validates :entrepreneur_id, presence: true
  validates :mentor_id, presence: true
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
  scope :countered, -> { where(status: COUNTERED) }
  scope :not_rejected_or_cancelled, -> { where.not(status: [ REJECTED, CANCELLED ]) }

  # Custom validation: ensure end date is after start date
  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  # Custom validation: ensure entrepreneur and mentor are different users
  def different_entrepreneur_and_mentor
    if entrepreneur_id.present? && mentor_id.present? && entrepreneur_id == mentor_id
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
    # If this is an original agreement, find counter offers made to it
    if counter_to_id.nil?
      Agreement.where(id: id).order(created_at: :desc).first
    else
      # If this is a counter offer, find newer counter offers made to the original agreement
      original_agreement = Agreement.find(counter_to_id)
      original_agreement.counter_offers.order(created_at: :desc).first
    end
  end

  # Status update methods
  def accept!
    return false unless pending?
    update(status: ACCEPTED)
  end

  def reject!
    return false unless pending?
    update(status: REJECTED)
  end

  def complete!
    return false unless active?
    update(status: COMPLETED)
  end

  def cancel!
    return false unless pending?
    update(status: CANCELLED)
  end

  def counter_offer!(counter_agreement)
    return false unless pending?

    # Mark this agreement as countered
    update(status: COUNTERED)

    # Link the new agreement to this one
    counter_agreement.counter_to_id = self.id
    counter_agreement.status = PENDING

    counter_agreement.save
  end

  def payment_details
    case payment_type
    when HOURLY
      "#{hourly_rate}$/hour"
    when EQUITY
      "#{equity_percentage}% equity"
    when HYBRID
      "#{hourly_rate}$/hour + #{equity_percentage}% equity"
    end
  end

  def can_view_full_project_details?(user)
    return true if entrepreneur_id == user.id
    return true if mentor_id == user.id
    false
  end

  def calculate_total_cost
    return nil unless hourly_rate.present? && weekly_hours.present?
    return 0 if hourly_rate == 0

    weeks = duration_in_weeks
    hourly_rate * weekly_hours * weeks
  end

  def duration_in_weeks
    return 0 unless start_date.present? && end_date.present?
    ((end_date - start_date).to_f / 7).ceil
  end

  def has_counter_offers?
    counter_offers.exists?
  end

  def most_recent_counter_offer
    counter_offers.order(created_at: :desc).first
  end

  def is_counter_offer?
    counter_to_id.present?
  end
end
