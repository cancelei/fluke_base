# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      class ProductivityMetricsController < BaseController
        before_action :set_project
        before_action :set_metric, only: %i[show]
        before_action -> { require_scope!("read:metrics") }, only: %i[index show summary]
        before_action -> { require_scope!("write:metrics") }, only: %i[create bulk_sync]

        # GET /api/v1/flukebase_connect/projects/:project_id/productivity_metrics
        def index
          metrics = @project.ai_productivity_metrics

          # Filter by type
          metrics = metrics.where(metric_type: params[:type]) if params[:type].present?

          # Filter by period type
          metrics = metrics.for_period(params[:period_type]) if params[:period_type].present?

          # Filter since timestamp
          metrics = metrics.since(Time.zone.parse(params[:since])) if params[:since].present?

          # Order by calculated_at desc
          metrics = metrics.order(created_at: :desc)

          # Pagination
          page = (params[:page] || 1).to_i
          per_page = [(params[:per_page] || 50).to_i, 100].min
          total = metrics.count
          metrics = metrics.offset((page - 1) * per_page).limit(per_page)

          render_success({
            metrics: metrics.map { |m| metric_to_hash(m) },
            meta: {
              total:,
              page:,
              per_page:,
              pages: (total.to_f / per_page).ceil
            }
          })
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/productivity_metrics/:id
        def show
          render_success({ metric: metric_to_hash(@metric) })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/productivity_metrics
        def create
          metric = @project.ai_productivity_metrics.build(metric_params)
          metric.user = current_user
          metric.synced_at = Time.current

          if metric.save
            render_success({ metric: metric_to_hash(metric) }, status: :created)
          else
            render_error("Failed to create metric", errors: metric.errors.full_messages)
          end
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/productivity_metrics/summary
        def summary
          period = params[:period] || "week"
          since_date = case period
                       when "day" then 1.day.ago
                       when "week" then 7.days.ago
                       when "month" then 30.days.ago
                       when "year" then 1.year.ago
                       else 7.days.ago
                       end

          aggregated = AiProductivityMetric.aggregate_for_project(@project.id, since: since_date)

          # Also get materialized view stats if available
          stat = @project.ai_productivity_stat
          stat&.class&.refresh_if_stale!

          render_success({
            summary: aggregated,
            stats: stat&.as_summary,
            period:,
            since: since_date
          })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/productivity_metrics/bulk_sync
        def bulk_sync
          results = { created: [], updated: [], errors: [] }

          metrics_params = params.require(:metrics)

          metrics_params.each do |metric_data|
            metric_data = metric_data.permit(
              :external_id, :metric_type, :period_type,
              :period_start, :period_end,
              metric_data: {}
            )

            external_id = metric_data[:external_id]

            if external_id.present?
              # Try to find existing metric by external_id
              metric = @project.ai_productivity_metrics.find_by(external_id:)

              if metric
                # Update existing
                if metric.update(metric_data.merge(synced_at: Time.current))
                  results[:updated] << metric_to_hash(metric)
                else
                  results[:errors] << { external_id:, errors: metric.errors.full_messages }
                end
              else
                # Create new
                metric = @project.ai_productivity_metrics.build(metric_data)
                metric.user = current_user
                metric.synced_at = Time.current

                if metric.save
                  results[:created] << metric_to_hash(metric)
                else
                  results[:errors] << { external_id:, errors: metric.errors.full_messages }
                end
              end
            else
              results[:errors] << { error: "external_id is required for sync" }
            end
          end

          # Refresh materialized view after bulk sync
          AiProductivityStat.refresh! if results[:created].any? || results[:updated].any?

          render_success({
            sync_results: results,
            summary: {
              created: results[:created].count,
              updated: results[:updated].count,
              errors: results[:errors].count
            }
          })
        end

        private

        def set_project
          project_id = params[:project_id].to_i
          @project = current_user.accessible_projects.find { |p| p.id == project_id }
          forbidden unless @project
        end

        def set_metric
          @metric = @project.ai_productivity_metrics.find(params[:id])
        end

        def metric_params
          params.require(:metric).permit(
            :metric_type,
            :period_type,
            :period_start,
            :period_end,
            :external_id,
            metric_data: {}
          )
        end

        def metric_to_hash(metric)
          {
            id: metric.id,
            project_id: metric.project_id,
            user_id: metric.user_id,
            metric_type: metric.metric_type,
            period_type: metric.period_type,
            period_start: metric.period_start,
            period_end: metric.period_end,
            metric_data: metric.metric_data,
            external_id: metric.external_id,
            synced_at: metric.synced_at,
            created_at: metric.created_at,
            updated_at: metric.updated_at
          }
        end
      end
    end
  end
end
