# frozen_string_literal: true

# == Schema Information
#
# Table name: project_memories
#
#  id          :bigint           not null, primary key
#  content     :text             not null
#  key         :string
#  memory_type :string           default("fact"), not null
#  rationale   :text
#  references  :jsonb
#  synced_at   :datetime
#  tags        :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  external_id :string
#  project_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_project_memories_on_external_id                 (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#  index_project_memories_on_project_id                  (project_id)
#  index_project_memories_on_project_id_and_key          (project_id,key) UNIQUE WHERE (key IS NOT NULL)
#  index_project_memories_on_project_id_and_memory_type  (project_id,memory_type)
#  index_project_memories_on_user_id                     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#

class ProjectMemory < ApplicationRecord
  include WebhookDispatchable

  # Memory types
  FACT = "fact"
  CONVENTION = "convention"
  GOTCHA = "gotcha"
  DECISION = "decision"

  MEMORY_TYPES = [FACT, CONVENTION, GOTCHA, DECISION].freeze
  TYPES = MEMORY_TYPES # Alias for backwards compatibility

  # Webhook configuration
  webhook_events create: "memory.created",
                 update: "memory.updated",
                 destroy: "memory.deleted"

  # Associations
  belongs_to :project
  belongs_to :user

  # Validations
  validates :memory_type, presence: true, inclusion: { in: MEMORY_TYPES }
  validates :content, presence: true
  validates :key, uniqueness: { scope: :project_id }, allow_nil: true
  validates :key, presence: true, if: :convention?
  validates :external_id, uniqueness: true, allow_nil: true

  # Scopes
  scope :facts, -> { where(memory_type: FACT) }
  scope :conventions, -> { where(memory_type: CONVENTION) }
  scope :gotchas, -> { where(memory_type: GOTCHA) }
  scope :decisions, -> { where(memory_type: DECISION) }
  scope :synced, -> { where.not(synced_at: nil) }
  scope :unsynced, -> { where(synced_at: nil) }
  scope :with_tag, ->(tag) { where("tags @> ?", [tag].to_json) }
  scope :search, ->(query) { where("content ILIKE ?", "%#{query}%") }
  scope :since, ->(timestamp) { where("updated_at > ?", timestamp) }

  # Callbacks
  before_validation :generate_key_from_content, if: :convention?
  after_commit :dispatch_synced_webhook, on: :update, if: :synced_at_previously_changed?

  # Instance methods
  def fact?
    memory_type == FACT
  end

  def convention?
    memory_type == CONVENTION
  end

  def gotcha?
    memory_type == GOTCHA
  end

  def decision?
    memory_type == DECISION
  end

  def synced?
    synced_at.present?
  end

  def mark_synced!(external_id: nil)
    update!(
      synced_at: Time.current,
      external_id: external_id || self.external_id
    )
  end

  # Convert to hash for API response
  def to_api_hash
    {
      id: id,
      memory_type: memory_type,
      content: content,
      key: key,
      rationale: rationale,
      tags: tags || [],
      references: references || {},
      external_id: external_id,
      synced_at: synced_at&.iso8601,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      user: {
        id: user.id,
        name: user.full_name
      }
    }
  end

  # Class methods for search
  class << self
    def ransackable_attributes(_auth_object = nil)
      %w[content memory_type key created_at updated_at synced_at]
    end

    def ransackable_associations(_auth_object = nil)
      %w[project user]
    end
  end

  private

  def generate_key_from_content
    return if key.present?

    # Generate a slug-like key from the first part of the content
    self.key = content.to_s
                      .split(/[.!?\n]/)
                      .first.to_s
                      .parameterize
                      .underscore
                      .truncate(50, omission: "")
  end

  def dispatch_synced_webhook
    return unless synced_at.present? && synced_at_previously_was.blank?

    dispatcher = WebhookDispatcherService.new(project)
    dispatcher.dispatch(
      "memory.synced",
      payload: to_api_hash,
      resource_id: id
    )
  rescue StandardError => e
    Rails.logger.error("Webhook dispatch failed: #{e.message}")
  end
end
