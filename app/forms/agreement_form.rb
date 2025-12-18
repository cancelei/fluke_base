class AgreementForm < ApplicationForm
  attribute :project_id, :integer
  attribute :initiator_user_id, :integer
  attribute :other_party_user_id, :integer
  attribute :agreement_type, :string
  attribute :payment_type, :string
  attribute :start_date, :date
  attribute :end_date, :date
  attribute :tasks, :string
  attribute :weekly_hours, :string
  attribute :hourly_rate, :string
  attribute :equity_percentage, :string
  attribute :milestone_ids, :string
  attribute :counter_agreement_id, :integer
  attribute :status, :string, default: Agreement::PENDING
  attribute :terms, :string

  validates :project_id, :initiator_user_id, :other_party_user_id, :agreement_type, :payment_type, presence: true
  validates :start_date, :end_date, :tasks, presence: true
  validates :weekly_hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 40, only_integer: true }, if: -> { agreement_type == Agreement::MENTORSHIP }
  validates :hourly_rate, presence: true, numericality: { greater_than_or_equal_to: 0 },
            if: -> { payment_type == Agreement::HOURLY || payment_type == Agreement::HYBRID }
  validates :equity_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            if: -> { payment_type == Agreement::EQUITY || payment_type == Agreement::HYBRID }
  validate :milestone_ids_presence, if: -> { agreement_type == Agreement::MENTORSHIP }

  validate :end_date_after_start_date
  validate :different_parties
  validate :valid_payment_terms
  validate :no_duplicate_agreement

  def initialize(attributes = {})
    super
    self.agreement_type = determine_agreement_type if agreement_type.blank?
    self.milestone_ids = parse_milestone_ids(attributes[:milestone_ids] || attributes["milestone_ids"])
  end

  def milestone_ids_array
    @milestone_ids_array ||= parse_milestone_ids(milestone_ids)
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
    @initiator ||= User.find(initiator_user_id) if initiator_user_id.present?
  end

  def other_party
    @other_party ||= User.find(other_party_user_id) if other_party_user_id.present?
  end

  def counter_to
    @counter_to ||= Agreement.find(counter_agreement_id) if counter_agreement_id.present?
  end

  def is_counter_offer?
    counter_agreement_id.present?
  end

  # Helper method to check if this is a counter offer during validation
  # This handles the case where counter_agreement_id might not be set yet
  def is_counter_offer_validation?
    counter_agreement_id.present?
  end

  def agreement
    @agreement
  end

  def update_agreement(agreement)
    @agreement = agreement
    @is_update = true
    assign_attributes_to_agreement

    if @agreement.save
      create_agreement_participants
      Rails.logger.info "Agreement #{@agreement.id} successfully updated"
      true
    else
      errors.merge!(@agreement.errors)
      false
    end
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
    create_agreement_participants
    true
  end

  def assign_attributes_to_agreement
    @agreement.assign_attributes(
      project_id: project_id || @agreement.project_id,
      agreement_type: agreement_type || @agreement.agreement_type,
      payment_type: payment_type || @agreement.payment_type,
      start_date: start_date || @agreement.start_date,
      end_date: end_date || @agreement.end_date,
      tasks: tasks || @agreement.tasks,
      weekly_hours: weekly_hours.nil? ? @agreement.weekly_hours : weekly_hours.to_i,
      hourly_rate: hourly_rate.nil? ? @agreement.hourly_rate : hourly_rate.to_f,
      equity_percentage: equity_percentage.nil? ? @agreement.equity_percentage : equity_percentage.to_f,
      milestone_ids: milestone_ids_array.presence || @agreement.milestone_ids,
      status: status || @agreement.status
    )
  end

  def create_agreement_participants
    return unless @agreement.persisted?

    # Clear existing participants if updating
    @agreement.agreement_participants.destroy_all if @is_update

    # For new agreements, the turn should go to the other party (receiver)
    turn_user_id = other_party_user_id

    # Create initiator participant
    initiator_role = determine_user_role(initiator_user_id)
    @agreement.agreement_participants.create!(
      user_id: initiator_user_id,
      user_role: initiator_role,
      project_id: project_id,
      is_initiator: true,
      counter_agreement_id: counter_agreement_id,
      accept_or_counter_turn_id: turn_user_id
    )

    # Create other party participant
    other_party_role = determine_user_role(other_party_user_id)
    @agreement.agreement_participants.create!(
      user_id: other_party_user_id,
      user_role: other_party_role,
      project_id: project_id,
      is_initiator: false,
      counter_agreement_id: counter_agreement_id,
      accept_or_counter_turn_id: turn_user_id
    )
  end

  def determine_user_role(user_id)
    # With simplified user system, determine role based on project ownership and agreement type
    if project.user_id == user_id
      "entrepreneur"
    else
      case agreement_type
      when Agreement::MENTORSHIP
        "mentor"
      when Agreement::CO_FOUNDER
        "co_founder"
      else
        "collaborator"
      end
    end
  end

  def setup_counter_offer(agreement)
    return unless is_counter_offer?

    original_agreement = counter_to
    return unless original_agreement

    # Update the original agreement status to COUNTERED
    original_agreement.update!(status: Agreement::COUNTERED)

    # The counter_agreement_id is already set in create_agreement_participants
    # Pass turn to the other party (the one who didn't make the counter offer)
    agreement.pass_turn_to_other_party(User.find(initiator_user_id))

    Rails.logger.info "Counter offer setup completed for agreement #{agreement.id} countering #{original_agreement.id}"
  end

  def determine_agreement_type
    weekly_hours.present? ? Agreement::MENTORSHIP : Agreement::CO_FOUNDER
  end

  def parse_milestone_ids(value)
    case value
    when nil
      []
    when Array
      value.map(&:to_i).reject(&:zero?)
    when String
      return [] if value.blank?
      # Try JSON first
      begin
        parsed = JSON.parse(value)
        return parsed.map(&:to_i).reject(&:zero?) if parsed.is_a?(Array)
      rescue JSON::ParserError
        # Not JSON, fall through
      end
      # Handle comma-separated string
      value.split(",").map(&:strip).map(&:to_i).reject(&:zero?)
    else
      []
    end
  end

  def milestone_ids_presence
    if milestone_ids_array.blank?
      errors.add(:milestone_ids, "can't be blank")
    end
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  def different_parties
    if initiator_user_id.present? && other_party_user_id.present? && initiator_user_id == other_party_user_id
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
    return unless project_id.present? && initiator_user_id.present? && other_party_user_id.present?

    # Debug logging
    Rails.logger.debug "no_duplicate_agreement validation: counter_agreement_id=#{counter_agreement_id}, is_counter_offer?=#{is_counter_offer?}"

    # Skip duplicate check for counter offers - they should be allowed
    return if is_counter_offer?

    # Check for existing agreements using the new AgreementParticipants structure
    query = Agreement.joins(:agreement_participants)
      .where(project_id: project_id, status: [ Agreement::ACCEPTED, Agreement::PENDING ])
      .where(agreement_participants: { user_id: [ initiator_user_id, other_party_user_id ] })
      .group("agreements.id")
      .having("COUNT(agreement_participants.id) = 2")

    # Exclude the current agreement if we're updating
    if @is_update && @agreement&.persisted?
      query = query.where.not(id: @agreement.id)
    end

    existing_agreement = query.first

    if existing_agreement.present?
      errors.add(:base, "An agreement already exists between these parties for this project")
    end
  end
end
