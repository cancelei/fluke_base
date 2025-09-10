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
