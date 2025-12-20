# frozen_string_literal: true

class Rating < ApplicationRecord
  # Associations
  belongs_to :rater, class_name: "User"
  belongs_to :rateable, polymorphic: true

  # Validations
  validates :value, presence: true, inclusion: { in: 1..5, message: "must be between 1 and 5" }
  validates :rater_id, uniqueness: {
    scope: [:rateable_type, :rateable_id],
    message: "has already rated this"
  }
  validate :cannot_rate_self

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(rateable: user) }
  scope :by_user, ->(user) { where(rater: user) }

  # Callbacks
  after_save :update_rateable_rating_cache
  after_destroy :update_rateable_rating_cache

  # Class methods for statistics
  class << self
    def average_rating
      average(:value)&.round(1) || 0.0
    end

    def rating_breakdown
      group(:value).count.transform_keys(&:to_i)
    end

    def rating_count
      count
    end
  end

  private

  def cannot_rate_self
    return unless rateable_type == "User" && rateable_id == rater_id

    errors.add(:base, "You cannot rate yourself")
  end

  def update_rateable_rating_cache
    return unless rateable.respond_to?(:update_rating_cache!)

    rateable.update_rating_cache!
  end
end
