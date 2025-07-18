class AgreementForm < ApplicationForm
  attribute :project_id, :integer
  attribute :initiator_id, :integer
  attribute :other_party_id, :integer
  attribute :agreement_type, :string
  attribute :payment_type, :string
  attribute :start_date, :date
  attribute :end_date, :date
  attribute :tasks, :string
  attribute :weekly_hours, :integer
  attribute :hourly_rate, :decimal
  attribute :equity_percentage, :decimal
  attribute :milestone_ids, :string
  attribute :counter_to_id, :integer
  attribute :status, :string, default: Agreement::PENDING
  attribute :initiator_meta, :string
  attribute :counter_offer_turn_id, :integer

  validates :project_id, :initiator_id, :other_party_id, :agreement_type, :payment_type, presence: true
  validates :start_date, :end_date, :tasks, :weekly_hours, presence: true
  validates :weekly_hours, numericality: { greater_than: 0, less_than_or_equal_to: 40 }
  validates :hourly_rate, presence: true, numericality: { greater_than_or_equal_to: 0 },
            if: -> { payment_type == Agreement::HOURLY || payment_type == Agreement::HYBRID }
  validates :equity_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            if: -> { payment_type == Agreement::EQUITY || payment_type == Agreement::HYBRID }
  validates :milestone_ids, presence: true, if: -> { agreement_type == Agreement::MENTORSHIP }

  validate :end_date_after_start_date
  validate :different_parties
  validate :valid_payment_terms
  validate :no_duplicate_agreement

  def initialize(attributes = {})
    super
    self.agreement_type = determine_agreement_type if agreement_type.blank?
    self.milestone_ids = parse_milestone_ids(milestone_ids)
  end

  def milestone_ids_array
    @milestone_ids_array ||= Array(milestone_ids).map(&:to_i).reject(&:zero?)
  end

  def milestone_ids=(value)
    @milestone_ids_array = nil
    super(parse_milestone_ids(value))
  end

  def selected_milestones
    return [] unless project_id.present?

    project = Project.find(project_id)
    project.milestones.where(id: milestone_ids_array)
  end

  def project
    @project ||= Project.find(project_id) if project_id.present?
  end

  def initiator
    @initiator ||= User.find(initiator_id) if initiator_id.present?
  end

  def other_party
    @other_party ||= User.find(other_party_id) if other_party_id.present?
  end

  def counter_to
    @counter_to ||= Agreement.find(counter_to_id) if counter_to_id.present?
  end

  def is_counter_offer?
    counter_to_id.present?
  end

  def agreement
    @agreement
  end

  def update_agreement(agreement)
    @agreement = agreement
    @is_update = true
    assign_attributes_to_agreement
    @agreement.save!
  end

  private

  def perform_save
    @agreement = Agreement.new
    @is_update = false
    assign_attributes_to_agreement

    if is_counter_offer?
      setup_counter_offer(@agreement)
    end

    @agreement.save!
  end

  def assign_attributes_to_agreement
    @agreement.assign_attributes(
      project_id: project_id,
      initiator_id: initiator_id,
      other_party_id: other_party_id,
      agreement_type: agreement_type,
      payment_type: payment_type,
      start_date: start_date,
      end_date: end_date,
      tasks: tasks,
      weekly_hours: weekly_hours,
      hourly_rate: hourly_rate,
      equity_percentage: equity_percentage,
      milestone_ids: milestone_ids_array,
      counter_to_id: counter_to_id,
      status: status,
      initiator_meta: initiator_meta,
      counter_offer_turn_id: counter_offer_turn_id || other_party_id
    )
  end

  def setup_counter_offer(agreement)
    original_agreement = counter_to
    agreement.initiator_meta = original_agreement.initiator_meta if original_agreement.initiator_meta.present?
    agreement.counter_offer_turn_id = agreement.other_party_id
    original_agreement.update!(status: Agreement::COUNTERED)
  end

  def determine_agreement_type
    weekly_hours.present? ? Agreement::MENTORSHIP : Agreement::CO_FOUNDER
  end

  def parse_milestone_ids(value)
    case value
    when String
      value.split(",").map(&:strip).map(&:to_i).reject(&:zero?)
    when Array
      value.map(&:to_i).reject(&:zero?)
    else
      []
    end
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  def different_parties
    if initiator_id.present? && other_party_id.present? && initiator_id == other_party_id
      errors.add(:base, "Initiator and other party cannot be the same person")
    end
  end

  def valid_payment_terms
    case payment_type
    when Agreement::HOURLY
      errors.add(:hourly_rate, "must be present for hourly payment") if hourly_rate.blank?
    when Agreement::EQUITY
      errors.add(:equity_percentage, "must be present for equity payment") if equity_percentage.blank?
    when Agreement::HYBRID
      errors.add(:hourly_rate, "must be present for hybrid payment") if hourly_rate.blank?
      errors.add(:equity_percentage, "must be present for hybrid payment") if equity_percentage.blank?
    end
  end

  def no_duplicate_agreement
    return unless project_id.present? && initiator_id.present? && other_party_id.present?
    return if is_counter_offer? # Counter offers are allowed

    existing = Agreement.where(
      project_id: project_id,
      initiator_id: initiator_id,
      other_party_id: other_party_id,
      status: [ Agreement::PENDING, Agreement::ACCEPTED ]
    ).exists?

    if existing
      errors.add(:base, "An agreement already exists between these parties for this project")
    end
  end
end
