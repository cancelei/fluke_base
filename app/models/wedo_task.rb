# frozen_string_literal: true

# == Schema Information
#
# Table name: wedo_tasks
#
#  id               :bigint           not null, primary key
#  artifact_path    :string
#  blocked_by       :jsonb
#  completed_at     :datetime
#  dependency       :string           default("AGENT_CAPABLE"), not null
#  description      :text             not null
#  due_date         :date
#  priority         :string           default("normal"), not null
#  remote_url       :string
#  scope            :string           default("global"), not null
#  status           :string           default("pending"), not null
#  synthesis_report :text             default("")
#  tags             :jsonb
#  version          :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  assignee_id      :bigint
#  created_by_id    :bigint
#  external_id      :string
#  parent_task_id   :bigint
#  project_id       :bigint           not null
#  task_id          :string           not null
#  template_id      :string
#  updated_by_id    :bigint
#
# Indexes
#
#  index_wedo_tasks_on_assignee_id             (assignee_id)
#  index_wedo_tasks_on_created_at              (created_at)
#  index_wedo_tasks_on_created_by_id           (created_by_id)
#  index_wedo_tasks_on_external_id             (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#  index_wedo_tasks_on_parent_task_id          (parent_task_id)
#  index_wedo_tasks_on_project_id              (project_id)
#  index_wedo_tasks_on_project_id_and_scope    (project_id,scope)
#  index_wedo_tasks_on_project_id_and_status   (project_id,status)
#  index_wedo_tasks_on_project_id_and_task_id  (project_id,task_id) UNIQUE
#  index_wedo_tasks_on_tags                    (tags) USING gin
#  index_wedo_tasks_on_updated_by_id           (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (parent_task_id => wedo_tasks.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class WedoTask < ApplicationRecord
  # =============================================================================
  # Constants
  # =============================================================================

  STATUSES = %w[pending in_progress completed blocked].freeze
  DEPENDENCIES = %w[USER_REQUIRED AGENT_CAPABLE].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  # =============================================================================
  # Relationships
  # =============================================================================

  belongs_to :project
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :parent_task, class_name: "WedoTask", optional: true
  has_many :subtasks, class_name: "WedoTask", foreign_key: :parent_task_id, dependent: :nullify

  # =============================================================================
  # Validations
  # =============================================================================

  validates :task_id, presence: true, uniqueness: { scope: :project_id }
  validates :description, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :dependency, inclusion: { in: DEPENDENCIES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :external_id, uniqueness: true, allow_nil: true

  # =============================================================================
  # Scopes
  # =============================================================================

  scope :pending, -> { where(status: "pending") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }
  scope :blocked, -> { where(status: "blocked") }
  scope :for_scope, ->(s) { where(scope: s) }
  scope :root_tasks, -> { where(parent_task_id: nil) }
  scope :with_tag, ->(tag) { where("tags @> ?", [tag].to_json) }
  scope :since_version, ->(v) { where("version > ?", v) }

  scope :by_priority, lambda {
    order(Arel.sql("CASE priority
      WHEN 'urgent' THEN 1
      WHEN 'high' THEN 2
      WHEN 'normal' THEN 3
      WHEN 'low' THEN 4
      END"))
  }

  scope :by_status_order, lambda {
    order(Arel.sql("CASE status
      WHEN 'in_progress' THEN 1
      WHEN 'blocked' THEN 2
      WHEN 'pending' THEN 3
      WHEN 'completed' THEN 4
      END"))
  }

  # =============================================================================
  # Callbacks
  # =============================================================================

  before_create :set_external_id
  before_save :increment_version, if: :will_save_change_to_attribute?
  before_save :set_completed_at, if: :completing?
  after_commit :broadcast_changes, on: [:create, :update]

  # =============================================================================
  # Instance Methods
  # =============================================================================

  # Status helpers
  def pending? = status == "pending"
  def in_progress? = status == "in_progress"
  def completed? = status == "completed"
  def blocked? = status == "blocked"

  # Progress tracking
  def progress_percentage
    return 0 if subtasks.empty?
    (subtasks.completed.count.to_f / subtasks.count * 100).round
  end

  # Dependency management
  def blocking_tasks
    return WedoTask.none if blocked_by.blank?
    WedoTask.where(task_id: blocked_by, project_id:)
  end

  def dependencies_met?
    blocking_tasks.all?(&:completed?)
  end

  def unmet_dependencies
    blocking_tasks.where.not(status: "completed")
  end

  # Synthesis report management (audit trail)
  def append_synthesis_note(note, agent_id: nil)
    timestamp = Time.current.iso8601
    agent_str = agent_id.present? ? " [#{agent_id}]" : ""
    new_entry = "- #{timestamp}#{agent_str}: #{note}"
    self.synthesis_report = [synthesis_report.presence, new_entry].compact.join("\n")
  end

  # API serialization
  def to_api_hash(include_subtasks: false)
    hash = {
      id:,
      task_id:,
      description:,
      status:,
      dependency:,
      scope:,
      priority:,
      synthesis_report:,
      artifact_path:,
      remote_url:,
      completed_at: completed_at&.iso8601,
      blocked_by: blocked_by || [],
      tags: tags || [],
      version:,
      external_id:,
      parent_task_id: parent_task&.task_id,
      template_id:,
      assignee: assignee&.full_name,
      assignee_id:,
      due_date: due_date&.iso8601,
      created_by: created_by&.full_name,
      created_by_id:,
      updated_by: updated_by&.full_name,
      updated_by_id:,
      progress_percent: progress_percentage,
      subtask_count: subtasks.count,
      completed_subtask_count: subtasks.completed.count,
      project_id:,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }

    hash[:subtasks] = subtasks.map(&:to_api_hash) if include_subtasks

    hash
  end

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[task_id description status dependency scope priority created_at updated_at assignee_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project created_by updated_by assignee parent_task subtasks]
  end

  private

  def set_external_id
    self.external_id ||= SecureRandom.uuid
  end

  def increment_version
    self.version += 1 if persisted?
  end

  def completing?
    status_changed? && status == "completed"
  end

  def set_completed_at
    self.completed_at ||= Time.current
  end

  def will_save_change_to_attribute?(attr_name = nil)
    return changed? && persisted? if attr_name.nil?
    super
  end

  def broadcast_changes
    return unless defined?(TeamBoardChannel)

    event_type = previously_new_record? ? "task.created" : "task.updated"
    event_type = "task.status_changed" if saved_change_to_status?

    # Extract agent_id from the most recent synthesis note if available
    agent_id = extract_agent_from_synthesis

    TeamBoardChannel.broadcast_task_event(
      project,
      event_type,
      self,
      agent_id:,
      include_milestone: true
    )
  rescue StandardError => e
    Rails.logger.warn "[WedoTask] Broadcast failed: #{e.message}"
  end

  def extract_agent_from_synthesis
    return nil if synthesis_report.blank?

    # Extract agent_id from format: "- timestamp [agent_id]: note"
    last_line = synthesis_report.lines.last
    match = last_line&.match(/\[([^\]]+)\]:/)
    match[1] if match
  end
end
