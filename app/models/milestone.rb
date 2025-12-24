# == Schema Information
#
# Table name: milestones
#
#  id          :bigint           not null, primary key
#  description :text
#  due_date    :date             not null
#  slug        :string
#  status      :string           not null
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  project_id  :bigint           not null
#
# Indexes
#
#  index_milestones_on_due_date                 (due_date)
#  index_milestones_on_project_id               (project_id)
#  index_milestones_on_project_id_and_due_date  (project_id,due_date)
#  index_milestones_on_project_id_and_slug      (project_id,slug) UNIQUE
#  index_milestones_on_project_id_and_status    (project_id,status)
#  index_milestones_on_status                   (status)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
class Milestone < ApplicationRecord
  extend FriendlyId

  belongs_to :project
  has_many :time_logs, dependent: :destroy
  has_many :milestone_enhancements, dependent: :destroy

  friendly_id :title, use: [:slugged, :scoped, :finders], scope: :project

  validates :title, :due_date, :status, presence: true

  # Statuses must match database constraint
  PENDING = "pending"
  IN_PROGRESS = "in_progress"
  COMPLETED = "completed"
  CANCELLED = "cancelled"

  scope :pending, -> { where(status: PENDING) }
  scope :in_progress, -> { where(status: IN_PROGRESS) }
  scope :completed, -> { where(status: COMPLETED) }
  scope :not_completed, -> { where.not(status: COMPLETED) }
  scope :upcoming, -> { where("due_date > ?", Date.today).order(due_date: :asc) }

  def completed? = status == COMPLETED

  # Get the actual status based on time logs and explicit status
  def actual_status
    return COMPLETED if status == COMPLETED

    # If milestone has time logs from project owner or agreement participants, it's in progress
    if has_time_logs_from_authorized_users?
      IN_PROGRESS
    elsif status == IN_PROGRESS
      # Allow explicit "In Progress" status even without time logs
      IN_PROGRESS
    else
      PENDING
    end
  end

  def has_time_logs_from_authorized_users?
    return false if time_logs.empty?

    # Cache authorized user IDs to prevent repeated queries
    @authorized_user_ids ||= begin
      project_owner_id = project.user_id
      agreement_participant_ids = project.agreements.active
                                        .joins(:agreement_participants)
                                        .pluck("agreement_participants.user_id")
      [project_owner_id] + agreement_participant_ids
    end

    time_logs.exists?(user_id: @authorized_user_ids)
  end

  def in_progress? = actual_status == IN_PROGRESS
  def not_started? = actual_status == PENDING
  def pending? = actual_status == PENDING
  def latest_enhancement = milestone_enhancements.recent.first
  def enhancement_history = milestone_enhancements.recent.limit(10)
  def has_successful_enhancement? = milestone_enhancements.successful.exists?
  def can_be_enhanced? = description.present?

  # Ransack configuration for search/filter functionality
  def self.ransackable_attributes(auth_object = nil)
    %w[status title due_date description project_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[project time_logs]
  end

  # FriendlyId: regenerate slug when title changes
  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
end
