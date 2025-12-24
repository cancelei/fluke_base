# == Schema Information
#
# Table name: milestone_enhancements
#
#  id                   :bigint           not null, primary key
#  context_data         :json
#  enhanced_description :text
#  enhancement_style    :string
#  original_description :text
#  processing_time_ms   :integer
#  status               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  milestone_id         :bigint           not null
#  user_id              :bigint           not null
#
# Indexes
#
#  index_milestone_enhancements_on_milestone_id  (milestone_id)
#  index_milestone_enhancements_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (milestone_id => milestones.id)
#  fk_rails_...  (user_id => users.id)
#
class MilestoneEnhancement < ApplicationRecord
  belongs_to :milestone
  belongs_to :user

  validates :original_description, presence: true
  validates :enhanced_description, presence: true, if: :successful?
  validates :enhancement_style, presence: true, inclusion: { in: %w[professional technical creative detailed concise] }
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }

  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: "completed") }
  scope :for_milestone, ->(milestone) { where(milestone:) }

  after_initialize :set_defaults, if: :new_record?

  def successful?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def processing?
    status == "processing"
  end

  def pending?
    status == "pending"
  end

  def processing_time_seconds
    return nil unless processing_time_ms
    processing_time_ms / 1000.0
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.context_data ||= {}
  end
end
