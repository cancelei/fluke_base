# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      class MemoriesController < BaseController
        before_action :set_project
        before_action :set_memory, only: %i[show update destroy]
        before_action -> { require_scope!("read:memories") }, only: %i[index show]
        before_action -> { require_scope!("write:memories") }, only: %i[create update destroy bulk_sync]

        # GET /api/v1/flukebase_connect/projects/:project_id/memories
        def index
          memories = @project.project_memories

          # Filter by type
          memories = memories.where(memory_type: params[:type]) if params[:type].present?

          # Filter by tag
          memories = memories.with_tag(params[:tag]) if params[:tag].present?

          # Filter by sync status
          memories = memories.synced if params[:synced] == "true"
          memories = memories.unsynced if params[:synced] == "false"

          # Filter by updated since timestamp
          memories = memories.since(Time.zone.parse(params[:since])) if params[:since].present?

          # Search content
          memories = memories.search(params[:q]) if params[:q].present?

          # Order by updated_at desc
          memories = memories.order(updated_at: :desc)

          # Pagination
          page = (params[:page] || 1).to_i
          per_page = [(params[:per_page] || 50).to_i, 100].min
          total = memories.count
          memories = memories.offset((page - 1) * per_page).limit(per_page)

          render_success({
            memories: memories.map(&:to_api_hash),
            meta: {
              total: total,
              page: page,
              per_page: per_page,
              pages: (total.to_f / per_page).ceil
            }
          })
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/memories/:id
        def show
          render_success({ memory: @memory.to_api_hash })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/memories
        def create
          memory = @project.project_memories.build(memory_params)
          memory.user = current_user

          if memory.save
            render_success({ memory: memory.to_api_hash }, status: :created)
          else
            render_error("Failed to create memory", errors: memory.errors.full_messages)
          end
        end

        # PUT /api/v1/flukebase_connect/projects/:project_id/memories/:id
        def update
          if @memory.update(memory_params)
            render_success({ memory: @memory.to_api_hash })
          else
            render_error("Failed to update memory", errors: @memory.errors.full_messages)
          end
        end

        # DELETE /api/v1/flukebase_connect/projects/:project_id/memories/:id
        def destroy
          @memory.destroy!
          render_success({ deleted: true })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/memories/bulk_sync
        # Sync multiple memories at once (upsert by external_id)
        def bulk_sync
          results = { created: [], updated: [], errors: [] }

          memories_params = params.require(:memories)

          memories_params.each do |memory_data|
            memory_data = memory_data.permit(
              :external_id, :memory_type, :content, :key,
              :rationale, tags: [], references: {}
            )

            external_id = memory_data[:external_id]

            if external_id.present?
              # Try to find existing memory by external_id
              memory = @project.project_memories.find_by(external_id: external_id)

              if memory
                # Update existing
                if memory.update(memory_data.merge(synced_at: Time.current))
                  results[:updated] << memory.to_api_hash
                else
                  results[:errors] << { external_id: external_id, errors: memory.errors.full_messages }
                end
              else
                # Create new
                memory = @project.project_memories.build(memory_data)
                memory.user = current_user
                memory.synced_at = Time.current

                if memory.save
                  results[:created] << memory.to_api_hash
                else
                  results[:errors] << { external_id: external_id, errors: memory.errors.full_messages }
                end
              end
            else
              results[:errors] << { error: "external_id is required for sync" }
            end
          end

          render_success({
            sync_results: results,
            summary: {
              created: results[:created].count,
              updated: results[:updated].count,
              errors: results[:errors].count
            }
          })
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/memories/conventions
        # Get all conventions formatted for AI context
        def conventions
          conventions = @project.project_memories.conventions.order(:key)

          render_success({
            conventions: conventions.map do |c|
              {
                key: c.key,
                value: c.content,
                rationale: c.rationale,
                tags: c.tags
              }
            end
          })
        end

        private

        def set_project
          project_id = params[:project_id].to_i
          @project = current_user.accessible_projects.find { |p| p.id == project_id }
          forbidden unless @project
        end

        def set_memory
          @memory = @project.project_memories.find(params[:id])
        end

        def memory_params
          params.require(:memory).permit(
            :memory_type,
            :content,
            :key,
            :rationale,
            :external_id,
            tags: [],
            references: {}
          )
        end
      end
    end
  end
end
