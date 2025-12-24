# == Schema Information
#
# Table name: agreement_participants
#
#  id                        :bigint           not null, primary key
#  is_initiator              :boolean          default(FALSE)
#  user_role                 :string           not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  accept_or_counter_turn_id :bigint
#  agreement_id              :bigint           not null
#  counter_agreement_id      :bigint
#  project_id                :bigint           not null
#  user_id                   :bigint           not null
#
# Indexes
#
#  idx_agreement_participants_on_agreement_user               (agreement_id,user_id) UNIQUE
#  idx_agreement_participants_on_is_initiator                 (is_initiator)
#  index_agreement_participants_on_accept_or_counter_turn_id  (accept_or_counter_turn_id)
#  index_agreement_participants_on_counter_agreement_id       (counter_agreement_id)
#  index_agreement_participants_on_project_id                 (project_id)
#  index_agreement_participants_on_user_id                    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (accept_or_counter_turn_id => users.id)
#  fk_rails_...  (agreement_id => agreements.id)
#  fk_rails_...  (counter_agreement_id => agreements.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
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
