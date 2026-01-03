# frozen_string_literal: true

# == Schema Information
#
# Table name: suggested_gotchas
#
#  id                 :bigint           not null, primary key
#  analyzed_at        :datetime
#  reviewed_at        :datetime
#  source_fingerprint :string
#  status             :string           default("pending"), not null
#  suggested_content  :text
#  suggested_title    :string
#  trigger_data       :jsonb
#  trigger_type       :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  approved_memory_id :bigint
#  project_id         :bigint           not null
#  reviewed_by_id     :bigint
#
# Indexes
#
#  index_suggested_gotchas_on_approved_memory_id     (approved_memory_id)
#  index_suggested_gotchas_on_project_id             (project_id)
#  index_suggested_gotchas_on_project_id_and_status  (project_id,status)
#  index_suggested_gotchas_on_reviewed_by_id         (reviewed_by_id)
#  index_suggested_gotchas_on_source_fingerprint     (source_fingerprint)
#  index_suggested_gotchas_on_status                 (status)
#  index_suggested_gotchas_on_trigger_type           (trigger_type)
#  index_suggested_gotchas_unique_fingerprint        (project_id,source_fingerprint) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (approved_memory_id => project_memories.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (reviewed_by_id => users.id)
#

# Auto-generated gotcha suggestions from error pattern analysis.
# These require human review before becoming ProjectMemories.
class SuggestedGotcha < ApplicationRecord
  include WebhookDispatchable

  # Webhook events for real-time notifications
  webhook_events create: "gotcha.suggested"
  # Trigger types that can generate suggestions
  RECURRING_ERROR = "recurring_error"
  HIGH_FAILURE = "high_failure"
  RETRY_SEQUENCE = "retry_sequence"
  LONG_DEBUGGING = "long_debugging"
  REPEATED_SEARCHES = "repeated_searches"

  TRIGGER_TYPES = [
    RECURRING_ERROR,
    HIGH_FAILURE,
    RETRY_SEQUENCE,
    LONG_DEBUGGING,
    REPEATED_SEARCHES
  ].freeze

  # Workflow statuses
  PENDING = "pending"
  APPROVED = "approved"
  DISMISSED = "dismissed"
  EDITED = "edited"

  STATUSES = [PENDING, APPROVED, DISMISSED, EDITED].freeze

  # Associations
  belongs_to :project
  belongs_to :approved_memory, class_name: "ProjectMemory", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  # Validations
  validates :trigger_type, presence: true, inclusion: { in: TRIGGER_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :suggested_content, presence: true
  validates :source_fingerprint, uniqueness: { scope: :project_id }, allow_nil: true

  # Scopes
  scope :pending, -> { where(status: PENDING) }
  scope :approved, -> { where(status: APPROVED) }
  scope :dismissed, -> { where(status: DISMISSED) }
  scope :reviewed, -> { where.not(status: PENDING) }
  scope :by_trigger, ->(type) { where(trigger_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  # Status predicates
  def pending?
    status == PENDING
  end

  def approved?
    status == APPROVED
  end

  def dismissed?
    status == DISMISSED
  end

  def edited?
    status == EDITED
  end

  def reviewable?
    pending?
  end

  # Workflow actions

  # Approve the suggestion and create a ProjectMemory
  def approve!(user:, content: nil, title: nil)
    transaction do
      final_content = content.presence || suggested_content
      final_title = title.presence || suggested_title

      # Create the project memory as a gotcha
      memory = project.project_memories.create!(
        memory_type: ProjectMemory::GOTCHA,
        content: final_content,
        user:,
        tags: build_tags,
        references: build_references
      )

      update!(
        status: content.present? ? EDITED : APPROVED,
        approved_memory: memory,
        reviewed_by: user,
        reviewed_at: Time.current,
        suggested_content: final_content,
        suggested_title: final_title
      )

      memory
    end
  end

  # Dismiss the suggestion
  def dismiss!(user:, reason: nil)
    update!(
      status: DISMISSED,
      reviewed_by: user,
      reviewed_at: Time.current,
      trigger_data: trigger_data.merge("dismiss_reason" => reason)
    )
  end

  # Trigger data accessors
  def fingerprint
    trigger_data["fingerprint"]
  end

  def occurrence_count
    trigger_data["count"] || 0
  end

  def tool_name
    trigger_data["tool_name"]
  end

  def error_message
    trigger_data["error_message"]
  end

  def error_category
    trigger_data["error_category"]
  end

  def sample_messages
    trigger_data["sample_messages"] || []
  end

  def failure_rate
    trigger_data["failure_rate"]
  end

  # Human-readable trigger type
  def trigger_type_label
    case trigger_type
    when RECURRING_ERROR then "Recurring Error"
    when HIGH_FAILURE then "High Failure Rate"
    when RETRY_SEQUENCE then "Retry Sequence"
    when LONG_DEBUGGING then "Long Debugging Session"
    when REPEATED_SEARCHES then "Repeated Searches"
    else trigger_type.titleize
    end
  end

  # API representation
  def to_api_hash
    {
      id:,
      trigger_type:,
      trigger_type_label:,
      trigger_data:,
      suggested_content:,
      suggested_title:,
      status:,
      occurrence_count:,
      tool_name:,
      error_category:,
      sample_messages:,
      analyzed_at: analyzed_at&.iso8601,
      reviewed_at: reviewed_at&.iso8601,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      project: {
        id: project.id,
        name: project.name
      }
    }
  end

  private

  def build_tags
    tags = ["auto-detected", trigger_type]
    tags << tool_name if tool_name.present?
    tags << error_category if error_category.present?
    tags
  end

  def build_references
    {
      "suggested_gotcha_id" => id,
      "trigger_type" => trigger_type,
      "occurrence_count" => occurrence_count,
      "fingerprint" => fingerprint,
      "detected_at" => analyzed_at&.iso8601
    }
  end
end
