# frozen_string_literal: true

# == Schema Information
#
# Table name: container_pools
#
#  id                        :bigint           not null, primary key
#  auto_delegate_enabled     :boolean          default(TRUE), not null
#  config                    :jsonb            not null
#  context_threshold_percent :integer          default(80), not null
#  last_activity_at          :datetime
#  max_pool_size             :integer          default(3), not null
#  skip_user_required        :boolean          default(TRUE), not null
#  status                    :string           default("active"), not null
#  warm_pool_size            :integer          default(1), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  project_id                :bigint           not null
#
# Indexes
#
#  index_container_pools_on_project_id  (project_id) UNIQUE
#  index_container_pools_on_status      (status)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
class ContainerPool < ApplicationRecord
  # =============================================================================
  # Constants
  # =============================================================================

  STATUSES = %w[active paused draining].freeze

  # =============================================================================
  # Associations
  # =============================================================================

  belongs_to :project
  has_many :container_sessions, dependent: :destroy

  # =============================================================================
  # Validations
  # =============================================================================

  validates :status, inclusion: { in: STATUSES }
  validates :warm_pool_size, numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :max_pool_size, numericality: { greater_than: 0, less_than_or_equal_to: 20 }
  validates :context_threshold_percent, numericality: { in: 50..95 }
  validate :max_pool_size_greater_than_warm

  # =============================================================================
  # Scopes
  # =============================================================================

  scope :active, -> { where(status: "active") }
  scope :paused, -> { where(status: "paused") }
  scope :with_capacity, -> { active.where("(SELECT COUNT(*) FROM container_sessions WHERE container_sessions.container_pool_id = container_pools.id AND container_sessions.status IN ('starting', 'active', 'idle')) < container_pools.max_pool_size") }

  # =============================================================================
  # Instance Methods
  # =============================================================================

  def active_session_count
    container_sessions.active.count
  end

  def idle_session_count
    container_sessions.available.count
  end

  def can_spawn_new_session?
    active? && active_session_count < max_pool_size
  end

  def needs_warmup?
    active? && idle_session_count < warm_pool_size
  end

  def active?
    status == "active"
  end

  def paused?
    status == "paused"
  end

  def pause!
    update!(status: "paused")
  end

  def resume!
    update!(status: "active")
  end

  def touch_activity!
    update_column(:last_activity_at, Time.current)
  end

  # Get an available session for task delegation
  # @param buffer_percent [Integer] Context buffer before threshold (default: 10)
  # @return [ContainerSession, nil] Available session or nil
  def find_available_session(buffer_percent: 10)
    threshold = context_threshold_percent - buffer_percent
    container_sessions
      .available
      .where("context_percent < ?", threshold)
      .order(:context_percent)
      .first
  end

  # API serialization
  def to_api_hash
    {
      id:,
      project_id:,
      status:,
      warm_pool_size:,
      max_pool_size:,
      context_threshold_percent:,
      auto_delegate_enabled:,
      skip_user_required:,
      active_sessions: active_session_count,
      idle_sessions: idle_session_count,
      can_spawn: can_spawn_new_session?,
      last_activity_at: last_activity_at&.iso8601,
      config:
    }
  end

  private

  def max_pool_size_greater_than_warm
    return if max_pool_size.nil? || warm_pool_size.nil?

    if max_pool_size < warm_pool_size
      errors.add(:max_pool_size, "must be greater than or equal to warm_pool_size")
    end
  end
end
