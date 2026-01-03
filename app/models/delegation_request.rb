# frozen_string_literal: true

# == Schema Information
#
# Table name: delegation_requests
#
#  id                   :bigint           not null, primary key
#  claimed_at           :datetime
#  completed_at         :datetime
#  metadata             :jsonb            not null
#  requested_by_session :string
#  status               :string           default("pending"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  container_session_id :bigint
#  project_id           :bigint           not null
#  wedo_task_id         :bigint           not null
#
# Indexes
#
#  index_delegation_requests_on_container_session_id     (container_session_id)
#  index_delegation_requests_on_project_id               (project_id)
#  index_delegation_requests_on_project_id_and_status    (project_id,status)
#  index_delegation_requests_on_wedo_task_id             (wedo_task_id)
#  index_delegation_requests_on_wedo_task_id_and_status  (wedo_task_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (container_session_id => container_sessions.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (wedo_task_id => wedo_tasks.id)
#
class DelegationRequest < ApplicationRecord
  # =============================================================================
  # Constants
  # =============================================================================

  STATUSES = %w[pending approved claimed completed cancelled expired].freeze

  # =============================================================================
  # Associations
  # =============================================================================

  belongs_to :project
  belongs_to :wedo_task
  belongs_to :container_session, optional: true

  # =============================================================================
  # Validations
  # =============================================================================

  validates :status, inclusion: { in: STATUSES }

  # =============================================================================
  # Scopes
  # =============================================================================

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :claimed, -> { where(status: "claimed") }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :active, -> { where(status: %w[pending approved claimed]) }
  scope :for_task, ->(task_id) { joins(:wedo_task).where(wedo_tasks: { task_id: task_id }) }

  # =============================================================================
  # Callbacks
  # =============================================================================

  after_save :broadcast_status_change, if: :saved_change_to_status?

  # =============================================================================
  # Instance Methods
  # =============================================================================

  # Status transitions
  def approve!
    update!(status: "approved")
  end

  def claim!(session)
    transaction do
      update!(
        status: "claimed",
        container_session: session,
        claimed_at: Time.current
      )
      wedo_task.update!(status: "in_progress") if wedo_task.status == "pending"
      session.assign_task!(wedo_task.task_id) if session.present?
    end
  end

  def complete!
    transaction do
      update!(
        status: "completed",
        completed_at: Time.current
      )
      container_session&.complete_task!
    end
  end

  def cancel!(reason = nil)
    update!(
      status: "cancelled",
      metadata: metadata.merge("cancel_reason" => reason, "cancelled_at" => Time.current.iso8601)
    )
  end

  def expire!
    update!(status: "expired")
  end

  # Check if task is delegable
  def self.can_delegate?(task)
    task.dependency == "AGENT_CAPABLE" &&
      task.status == "pending" &&
      !claimed.exists?(wedo_task: task)
  end

  # Atomic claim - prevents double-delegation
  # @param task [WedoTask] The task to claim
  # @param session [ContainerSession] The session claiming the task
  # @return [DelegationRequest, nil] The claimed request or nil if already claimed
  def self.atomic_claim(task, session)
    transaction do
      # Lock and check for existing claims
      existing = lock.find_by(wedo_task: task, status: "claimed")
      return nil if existing && existing.container_session_id != session.id

      # Find or create the request
      request = find_or_initialize_by(wedo_task: task, project: task.project)
      request.claim!(session)
      request
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  # API serialization
  def to_api_hash
    {
      id: id,
      task_id: wedo_task.task_id,
      project_id: project_id,
      status: status,
      container_session_id: container_session_id,
      session_id: container_session&.session_id,
      requested_by_session: requested_by_session,
      claimed_at: claimed_at&.iso8601,
      completed_at: completed_at&.iso8601,
      created_at: created_at.iso8601,
      metadata: metadata
    }
  end

  private

  def broadcast_status_change
    TeamBoardChannel.broadcast_to(project, {
      type: "delegation.#{status}",
      data: {
        request_id: id,
        task_id: wedo_task.task_id,
        session_id: container_session&.session_id,
        status: status
      },
      timestamp: Time.current.iso8601
    })
  end
end
