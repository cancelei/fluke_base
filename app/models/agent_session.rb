# frozen_string_literal: true

# == Schema Information
#
# Table name: agent_sessions
#
#  id                :bigint           not null, primary key
#  agent_id          :string           not null
#  agent_type        :string           default("claude_code")
#  capabilities      :jsonb
#  client_version    :string
#  connected_at      :datetime
#  disconnected_at   :datetime
#  ip_address        :string
#  last_heartbeat_at :datetime
#  metadata          :jsonb
#  persona_name      :string
#  status            :string           default("active"), not null
#  tokens_used       :integer          default(0)
#  tools_executed    :integer          default(0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  project_id        :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_agent_sessions_on_agent_id                 (agent_id)
#  index_agent_sessions_on_last_heartbeat_at        (last_heartbeat_at)
#  index_agent_sessions_on_persona_name             (persona_name)
#  index_agent_sessions_on_project_id               (project_id)
#  index_agent_sessions_on_project_id_and_agent_id  (project_id,agent_id) UNIQUE
#  index_agent_sessions_on_project_id_and_status    (project_id,status)
#  index_agent_sessions_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class AgentSession < ApplicationRecord
  # =============================================================================
  # Constants
  # =============================================================================

  STATUSES = %w[active idle disconnected].freeze
  AGENT_TYPES = %w[claude_code windsurf cursor gemini_cli copilot other].freeze
  HEARTBEAT_TIMEOUT = 2.minutes

  # =============================================================================
  # Relationships
  # =============================================================================

  belongs_to :project
  belongs_to :user

  # =============================================================================
  # Validations
  # =============================================================================

  validates :agent_id, presence: true, uniqueness: { scope: :project_id }
  validates :status, inclusion: { in: STATUSES }
  validates :agent_type, inclusion: { in: AGENT_TYPES }, allow_nil: true

  # =============================================================================
  # Scopes
  # =============================================================================

  scope :active, -> { where(status: "active") }
  scope :idle, -> { where(status: "idle") }
  scope :disconnected, -> { where(status: "disconnected") }
  scope :connected, -> { where(status: %w[active idle]) }
  scope :with_persona, -> { where.not(persona_name: nil) }
  scope :by_type, ->(type) { where(agent_type: type) }

  scope :recently_active, lambda {
    where("last_heartbeat_at > ?", HEARTBEAT_TIMEOUT.ago)
  }

  scope :stale, lambda {
    where("last_heartbeat_at < ?", HEARTBEAT_TIMEOUT.ago)
      .where.not(status: "disconnected")
  }

  # =============================================================================
  # Callbacks
  # =============================================================================

  before_create :set_connected_at
  before_save :check_idle_status

  # =============================================================================
  # Instance Methods
  # =============================================================================

  # Status helpers
  def active? = status == "active"
  def idle? = status == "idle"
  def disconnected? = status == "disconnected"
  def connected? = status.in?(%w[active idle])

  # Heartbeat management
  def heartbeat!(ip: nil, metadata: nil)
    attrs = {
      last_heartbeat_at: Time.current,
      status: "active"
    }
    attrs[:ip_address] = ip if ip.present?
    attrs[:metadata] = self.metadata.merge(metadata) if metadata.present?

    update!(attrs)
  end

  def stale?
    return false if last_heartbeat_at.nil?
    last_heartbeat_at < HEARTBEAT_TIMEOUT.ago
  end

  # Mark as idle (no recent activity but still connected)
  def mark_idle!
    update!(status: "idle") if active?
  end

  # Mark as disconnected
  def disconnect!
    update!(
      status: "disconnected",
      disconnected_at: Time.current
    )
  end

  # Record tool execution
  def record_tool_execution!(tokens: 0)
    increment!(:tools_executed)
    increment!(:tokens_used, tokens) if tokens.positive?
    heartbeat!
  end

  # Time since last activity
  def last_seen_ago
    return nil if last_heartbeat_at.nil?
    Time.current - last_heartbeat_at
  end

  # Human-readable display name
  def display_name
    persona_name.presence || agent_id.truncate(20)
  end

  # API serialization
  def to_api_hash
    {
      id:,
      agent_id:,
      persona_name:,
      agent_type:,
      status:,
      display_name:,
      connected_at: connected_at&.iso8601,
      disconnected_at: disconnected_at&.iso8601,
      last_heartbeat_at: last_heartbeat_at&.iso8601,
      last_seen_ago_seconds: last_seen_ago&.to_i,
      is_stale: stale?,
      capabilities: capabilities || [],
      client_version:,
      ip_address:,
      tools_executed:,
      tokens_used:,
      metadata: metadata || {},
      project_id:,
      user_id:,
      user_name: user.full_name,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  # =============================================================================
  # Class Methods
  # =============================================================================

  # Register or update an agent session
  def self.register!(project:, user:, agent_id:, **attrs)
    session = find_or_initialize_by(project:, agent_id:)

    session.assign_attributes(
      user:,
      status: "active",
      connected_at: session.new_record? ? Time.current : session.connected_at,
      last_heartbeat_at: Time.current,
      **attrs.slice(:persona_name, :agent_type, :capabilities, :metadata, :ip_address, :client_version)
    )

    session.save!
    session
  end

  # Mark stale sessions as idle
  def self.mark_stale_as_idle!
    stale.find_each(&:mark_idle!)
  end

  # Disconnect all stale idle sessions
  def self.disconnect_stale!
    idle.where("last_heartbeat_at < ?", 10.minutes.ago).find_each(&:disconnect!)
  end

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[agent_id persona_name agent_type status created_at last_heartbeat_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project user]
  end

  private

  def set_connected_at
    self.connected_at ||= Time.current
    self.last_heartbeat_at ||= Time.current
  end

  def check_idle_status
    return unless last_heartbeat_at_changed? && stale? && active?
    self.status = "idle"
  end
end
