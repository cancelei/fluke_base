# == Schema Information
#
# Table name: dashboard_stats
#
#  active_agreements          :bigint
#  agreements_as_initiator    :bigint
#  agreements_as_participant  :bigint
#  calculated_at              :timestamptz
#  completed_agreements       :bigint
#  completed_milestones       :bigint
#  email                      :string
#  in_progress_milestones     :bigint
#  pending_agreements         :bigint
#  projects_seeking_cofounder :bigint
#  projects_seeking_mentor    :bigint
#  total_agreements           :bigint
#  total_meetings             :bigint
#  total_milestones           :bigint
#  total_projects             :bigint
#  upcoming_meetings          :bigint
#  user_id                    :bigint           primary key
#
# Indexes
#
#  index_dashboard_stats_on_user_id  (user_id) UNIQUE
#
class DashboardStat < ApplicationRecord
  self.table_name = "dashboard_stats"
  self.primary_key = "user_id"

  belongs_to :user, foreign_key: "user_id"

  # Since this is a materialized view, we should refresh it periodically
  def self.refresh!
    connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY dashboard_stats")
  end

  # Get stats for a specific user
  def self.for_user(user)
    find_by(user_id: user.id)
  end

  # Check if stats are stale (older than 1 hour)
  def stale?
    calculated_at < 1.hour.ago
  end
end
