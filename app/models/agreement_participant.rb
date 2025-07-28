class AgreementParticipant < ApplicationRecord
  # Associations
  belongs_to :agreement
  belongs_to :user
  belongs_to :project
  belongs_to :counter_agreement, class_name: "Agreement", optional: true
  belongs_to :accept_or_counter_turn, class_name: "User", optional: true

  # Validations
  validates :agreement_id, presence: true
  validates :user_id, presence: true
  validates :project_id, presence: true
  validates :user_role, presence: true
  validates :is_initiator, inclusion: { in: [ true, false ] }
  validates :user_id, uniqueness: { scope: :agreement_id }

  # Scopes
  scope :initiators, -> { where(is_initiator: true) }
  scope :non_initiators, -> { where(is_initiator: false) }
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :for_agreement, ->(agreement) { where(agreement_id: agreement.id) }

  # Class methods
  def self.find_initiator(agreement)
    find_by(agreement: agreement, is_initiator: true)
  end

  def self.find_other_party(agreement, current_user)
    where(agreement: agreement).where.not(user_id: current_user.id).first
  end

  def self.find_participants(agreement)
    where(agreement: agreement)
  end

  # Instance methods
  def initiator?
    is_initiator
  end

  def can_accept_or_counter?
    accept_or_counter_turn_id == user_id
  end

  def other_participants
    self.class.where(agreement: agreement).where.not(id: id)
  end

  def is_turn_to_act?
    accept_or_counter_turn_id == user_id
  end

  # Turn-based system methods
  def pass_turn_to(next_user)
    update!(accept_or_counter_turn_id: next_user.id)
    # Also update other participants in the same agreement
    other_participants.update_all(accept_or_counter_turn_id: next_user.id)
  end

  def can_make_counter_offer?
    is_turn_to_act? && agreement.pending?
  end

  def can_accept_agreement?
    is_turn_to_act? && agreement.pending?
  end

  def can_reject_agreement?
    is_turn_to_act? && agreement.pending?
  end
end
