class AgreementParticipant < ApplicationRecord
  belongs_to :agreement
  belongs_to :user
  belongs_to :project
  belongs_to :counter_agreement, class_name: "Agreement", optional: true
  belongs_to :accept_or_counter_turn, class_name: "User", optional: true

  validates :agreement_id, presence: true
  validates :user_id, presence: true
  validates :project_id, presence: true
  validates :user_role, presence: true
  validates :is_initiator, inclusion: { in: [true, false] }
  validates :user_id, uniqueness: { scope: :agreement_id }

  scope :initiators, -> { where(is_initiator: true) }
  scope :non_initiators, -> { where(is_initiator: false) }
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :for_agreement, ->(agreement) { where(agreement_id: agreement.id) }

  def self.find_initiator(agreement) = find_by(agreement:, is_initiator: true)
  def self.find_other_party(agreement, current_user) = where(agreement:).where.not(user_id: current_user.id).first
  def self.find_participants(agreement) = where(agreement:)

  def initiator? = is_initiator
  def can_accept_or_counter? = accept_or_counter_turn_id == user_id && agreement.status == Agreement::PENDING
  def other_participants = self.class.where(agreement:).where.not(id:)
  def is_turn_to_act? = accept_or_counter_turn_id == user_id

  def pass_turn_to(next_user)
    update!(accept_or_counter_turn_id: next_user.id)
    # Also update other participants in the same agreement
    other_participants.update_all(accept_or_counter_turn_id: next_user.id)
  end

  def can_make_counter_offer? = is_turn_to_act? && agreement.pending?
  def can_accept_agreement? = is_turn_to_act? && agreement.pending?
  def can_reject_agreement? = is_turn_to_act? && agreement.pending?
end
