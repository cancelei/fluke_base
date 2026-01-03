# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      # API controller for syncing AI conversation logs from flukebase_connect.
      # Enables the Unified Logs dashboard to display AI provider chat exchanges.
      #
      # Endpoints:
      #   GET  /projects/:project_id/ai_conversations - List recent conversations
      #   POST /projects/:project_id/ai_conversations/bulk_sync - Bulk upsert logs
      class AiConversationsController < BaseController
        before_action :require_read_scope!, only: [:index, :show]
        before_action :require_write_scope!, only: [:bulk_sync]
        before_action :set_project

        # GET /api/v1/flukebase_connect/projects/:project_id/ai_conversations
        # List recent AI conversation logs for a project
        def index
          logs = @project.ai_conversation_logs
                         .includes(:user)
                         .recent(params[:limit] || 100)

          # Optional filters
          logs = logs.by_provider(params[:provider]) if params[:provider].present?
          logs = logs.by_session(params[:session_id]) if params[:session_id].present?
          logs = logs.by_role(params[:role]) if params[:role].present?

          render_success({
            logs: logs.map(&:to_unified_log_entry),
            count: logs.size,
            project_id: @project.id
          })
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/ai_conversations/:id
        def show
          log = @project.ai_conversation_logs.find(params[:id])
          render_success({ log: log.to_unified_log_entry })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/ai_conversations/bulk_sync
        # Bulk upsert AI conversation logs from flukebase_connect
        #
        # Request body:
        #   {
        #     "logs": [
        #       {
        #         "external_id": "unique-id",
        #         "provider": "claude",
        #         "model": "claude-3-opus",
        #         "session_id": "session-abc123",
        #         "message_index": 0,
        #         "role": "user",
        #         "content": "Hello!",
        #         "input_tokens": 10,
        #         "output_tokens": null,
        #         "duration_ms": null,
        #         "metadata": {},
        #         "exchanged_at": "2024-01-01T12:00:00Z"
        #       }
        #     ],
        #     "broadcast": true  # optional, broadcasts to UnifiedLogsChannel
        #   }
        def bulk_sync
          logs_params = params.require(:logs)

          unless logs_params.is_a?(Array)
            return render_error("logs must be an array", status: :bad_request)
          end

          results = { synced: 0, created: 0, updated: 0, errors: [] }
          created_logs = []

          ActiveRecord::Base.transaction do
            logs_params.each_with_index do |log_data, index|
              begin
                log = upsert_log(log_data)
                results[:synced] += 1

                if log.previously_new_record?
                  results[:created] += 1
                  created_logs << log
                else
                  results[:updated] += 1
                end
              rescue ActiveRecord::RecordInvalid => e
                results[:errors] << {
                  index:,
                  external_id: log_data[:external_id],
                  error: e.message
                }
              rescue StandardError => e
                results[:errors] << {
                  index:,
                  external_id: log_data[:external_id],
                  error: e.message
                }
              end
            end
          end

          # Broadcast new logs to UnifiedLogsChannel if requested
          if params[:broadcast] != false && created_logs.any?
            broadcast_logs(created_logs)
          end

          render_success(results)
        end

        private

        def set_project
          @project = current_user.projects.find(params[:project_id])
        rescue ActiveRecord::RecordNotFound
          # Also check projects user has access to via agreements
          @project = Project.joins(:agreements)
                            .where(agreements: { user_id: current_user.id })
                            .find(params[:project_id])
        end

        def require_read_scope!
          require_scope!("read:metrics")
        end

        def require_write_scope!
          require_scope!("write:metrics")
        end

        def upsert_log(log_data)
          attrs = permitted_log_attributes(log_data)

          if attrs[:external_id].present?
            log = @project.ai_conversation_logs
                          .find_or_initialize_by(external_id: attrs[:external_id])
            log.assign_attributes(attrs)
          else
            log = @project.ai_conversation_logs.new(attrs)
          end

          log.user = current_user unless log.user_id
          log.save!
          log
        end

        def permitted_log_attributes(log_data)
          {
            provider: log_data[:provider],
            model: log_data[:model],
            session_id: log_data[:session_id],
            external_id: log_data[:external_id],
            message_index: log_data[:message_index] || 0,
            role: log_data[:role],
            content: log_data[:content],
            input_tokens: log_data[:input_tokens],
            output_tokens: log_data[:output_tokens],
            duration_ms: log_data[:duration_ms],
            metadata: log_data[:metadata] || {},
            exchanged_at: parse_timestamp(log_data[:exchanged_at])
          }.compact
        end

        def parse_timestamp(ts)
          return nil if ts.blank?

          Time.zone.parse(ts)
        rescue ArgumentError
          nil
        end

        def broadcast_logs(logs)
          logs.each do |log|
            entry = log.to_unified_log_entry
            UnifiedLogsChannel.broadcast_log(entry)
          end
        rescue StandardError => e
          Rails.logger.error "[AiConversationsController] Broadcast error: #{e.message}"
        end
      end
    end
  end
end
