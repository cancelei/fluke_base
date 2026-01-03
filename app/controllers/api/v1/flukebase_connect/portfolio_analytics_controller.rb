# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      # Provides portfolio-level analytics across all user projects.
      # Unlike other controllers that operate on a single project,
      # this aggregates metrics across the user's entire portfolio.
      class PortfolioAnalyticsController < BaseController
        before_action -> { require_scope!("read:metrics") }

        # GET /api/v1/flukebase_connect/portfolio/summary
        # Returns aggregated productivity metrics across all accessible projects
        def summary
          service = ::FlukebaseConnect::PortfolioAnalyticsService.new(current_user)
          period = parse_period(params[:period])

          render_success({
            portfolio: service.aggregate(period:),
            generated_at: Time.current.iso8601
          })
        end

        # GET /api/v1/flukebase_connect/portfolio/compare
        # Returns ranked list of projects by productivity metrics
        def compare
          service = ::FlukebaseConnect::PortfolioAnalyticsService.new(current_user)
          period = parse_period(params[:period])
          sort_by = validate_sort_by(params[:sort_by])
          limit = parse_limit(params[:limit])

          render_success({
            projects: service.compare_projects(period:, sort_by:, limit:),
            sort_by:,
            period_days: period
          })
        end

        # GET /api/v1/flukebase_connect/portfolio/trends
        # Returns time-series productivity data grouped by day or week
        def trends
          service = ::FlukebaseConnect::PortfolioAnalyticsService.new(current_user)
          period = parse_period(params[:period], min: 7)
          granularity = validate_granularity(params[:granularity])

          render_success({
            trends: service.trends(period:, granularity:),
            granularity:,
            period_days: period
          })
        end

        private

        def parse_period(value, min: 1, max: 365, default: 30)
          period = (value || default).to_i
          period.clamp(min, max)
        end

        def parse_limit(value, min: 1, max: 50, default: 10)
          limit = (value || default).to_i
          limit.clamp(min, max)
        end

        def validate_sort_by(value)
          valid_fields = %w[time_saved tasks_completed tokens_used sessions_count cost]
          valid_fields.include?(value) ? value : "time_saved"
        end

        def validate_granularity(value)
          %w[daily weekly].include?(value) ? value : "daily"
        end
      end
    end
  end
end
