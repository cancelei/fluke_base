class RefreshDashboardStatsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Refreshing dashboard stats materialized view"

    begin
      DashboardStat.refresh!
      Rails.logger.info "Dashboard stats materialized view refreshed successfully"
    rescue => e
      Rails.logger.error "Failed to refresh dashboard stats: #{e.message}"
      raise e
    end
  end
end
