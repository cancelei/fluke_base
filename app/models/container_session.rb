# frozen_string_literal: true

# == Schema Information
#
# Table name: container_sessions
#
#  id                    :bigint           not null, primary key
#  context_max_tokens    :integer          default(100000)
#  context_percent       :float            default(0.0)
#  context_used_tokens   :integer          default(0)
#  handoff_summary       :text
#  last_activity_at      :datetime
#  last_context_check_at :datetime
#  metadata              :jsonb            not null
#  status                :string           default("starting"), not null
#  tasks_completed       :integer          default(0)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  agent_session_id      :bigint
#  container_id          :string
#  container_pool_id     :bigint           not null
#  current_task_id       :string
#  handoff_from_id       :bigint
#  session_id            :string           not null
#
# Indexes
#
#  index_container_sessions_on_agent_session_id              (agent_session_id)
#  index_container_sessions_on_container_pool_id             (container_pool_id)
#  index_container_sessions_on_container_pool_id_and_status  (container_pool_id,status)
#  index_container_sessions_on_context_percent               (context_percent)
#  index_container_sessions_on_handoff_from_id               (handoff_from_id)
#  index_container_sessions_on_session_id                    (session_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (agent_session_id => agent_sessions.id)
#  fk_rails_...  (container_pool_id => container_pools.id)
#  fk_rails_...  (handoff_from_id => container_sessions.id)
#
class ContainerSession < ApplicationRecord
  # =============================================================================
  # Constants
  # =============================================================================

  STATUSES = %w[starting active idle handoff_pending retired error].freeze

  # =============================================================================
  # Associations
  # =============================================================================

  belongs_to :container_pool
  belongs_to :agent_session, optional: true
  belongs_to :handoff_from, class_name: "ContainerSession", optional: true
  has_one :handoff_to, class_name: "ContainerSession", foreign_key: :handoff_from_id, dependent: :nullify, inverse_of: :handoff_from
  has_many :delegation_requests, dependent: :nullify

  # Delegate project access
  delegate :project, to: :container_pool

  # =============================================================================
  # Validations
  # =============================================================================

  validates :session_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  # =============================================================================
  # Scopes
  # =============================================================================

  scope :active, -> { where(status: %w[starting active idle]) }
  scope :available, -> { where(status: "idle") }
  scope :running, -> { where(status: %w[active]) }
  scope :pending_handoff, -> { where(status: "handoff_pending") }
  scope :retired, -> { where(status: "retired") }
  scope :approaching_threshold, lambda {
    joins(:container_pool)
      .where("container_sessions.context_percent >= container_pools.context_threshold_percent - 10")
  }

  # =============================================================================
  # Callbacks
  # =============================================================================

  after_save :broadcast_status_change, if: :saved_change_to_status?

  # =============================================================================
  # Instance Methods
  # =============================================================================

  # Context threshold checks
  def approaching_threshold?
    context_percent >= container_pool.context_threshold_percent - 10
  end

  def at_threshold?
    context_percent >= container_pool.context_threshold_percent
  end

  def context_available_percent
    100.0 - context_percent
  end

  # Update context usage from flukebase_connect report
  # @param used [Integer] Tokens used
  # @param max [Integer] Max tokens
  # @return [Hash] Action recommendation
  def update_context_usage!(used:, max:)
    update!(
      context_used_tokens: used,
      context_max_tokens: max,
      context_percent: (used.to_f / max * 100).round(2),
      last_context_check_at: Time.current
    )

    determine_context_action
  end

  # Determine recommended action based on context usage
  # @return [Hash] Action and reason
  def determine_context_action
    if context_percent >= container_pool.context_threshold_percent
      { action: "handoff_required", reason: "Context at #{context_percent.round(1)}%" }
    elsif approaching_threshold?
      { action: "prepare_handoff", reason: "Context approaching threshold at #{context_percent.round(1)}%" }
    else
      { action: "continue", reason: "Context at #{context_percent.round(1)}% - capacity available" }
    end
  end

  # Status transitions
  def mark_active!
    update!(status: "active", last_activity_at: Time.current)
    container_pool.touch_activity!
  end

  def mark_idle!
    update!(status: "idle", current_task_id: nil)
  end

  def mark_handoff_pending!
    update!(status: "handoff_pending")
  end

  def retire!(summary: nil)
    update!(
      status: "retired",
      handoff_summary: summary,
      current_task_id: nil
    )
  end

  def mark_error!(reason = nil)
    update!(
      status: "error",
      metadata: metadata.merge("error_reason" => reason, "error_at" => Time.current.iso8601)
    )
  end

  # Task assignment
  def assign_task!(task_id)
    update!(
      current_task_id: task_id,
      status: "active",
      last_activity_at: Time.current
    )
    container_pool.touch_activity!
  end

  def complete_task!
    increment!(:tasks_completed)
    update!(current_task_id: nil, status: "idle")
  end

  # Check if session can accept new tasks
  def can_accept_task?
    status.in?(%w[idle]) && current_task_id.nil? && !at_threshold?
  end

  # API serialization
  def to_api_hash
    {
      id:,
      session_id:,
      container_id:,
      status:,
      context: {
        used_tokens: context_used_tokens,
        max_tokens: context_max_tokens,
        percent: context_percent.round(2),
        last_check: last_context_check_at&.iso8601
      },
      current_task_id:,
      tasks_completed:,
      last_activity_at: last_activity_at&.iso8601,
      handoff_from_id:,
      can_accept_task: can_accept_task?,
      approaching_threshold: approaching_threshold?,
      at_threshold: at_threshold?,
      created_at: created_at.iso8601,
      metadata:
    }
  end

  private

  def broadcast_status_change
    TeamBoardChannel.broadcast_to(project, {
      type: "container_session.status_changed",
      data: {
        session_id:,
        status:,
        previous_status: status_before_last_save
      },
      timestamp: Time.current.iso8601
    })
  end
end
