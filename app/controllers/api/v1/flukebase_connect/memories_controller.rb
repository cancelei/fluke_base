# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      class MemoriesController < BaseController
        include BatchProjectResolvable

        before_action :set_project, except: [:cross_project_search, :batch_pull]
        before_action :set_memory, only: %i[show update destroy]
        before_action -> { require_scope!("read:memories") }, only: %i[index show cross_project_search batch_pull]
        before_action -> { require_scope!("write:memories") }, only: %i[create update destroy bulk_sync]
        before_action :validate_memory_type_param, only: %i[index cross_project_search batch_pull]

        VALID_MEMORY_TYPES = %w[fact convention gotcha decision].freeze

        # GET /api/v1/flukebase_connect/memories/search
        # Search memories across ALL accessible projects
        def cross_project_search
          project_ids = current_user.accessible_projects.map(&:id)
          memories = ProjectMemory.where(project_id: project_ids)

          # Filter by type
          memories = memories.where(memory_type: params[:type]) if params[:type].present?

          # Filter by tag
          memories = memories.with_tag(params[:tag]) if params[:tag].present?

          # Search content
          memories = memories.search(params[:q]) if params[:q].present?

          # Order by updated_at desc
          memories = memories.order(updated_at: :desc)

          # Pagination
          page = (params[:page] || 1).to_i
          per_page = [(params[:per_page] || 50).to_i, 100].min
          total = memories.count
          memories = memories.includes(:project).offset((page - 1) * per_page).limit(per_page)

          render_success({
            memories: memories.map { |m|
              m.to_api_hash.merge(project: { id: m.project_id, name: m.project.name })
            },
            meta: {
              total:,
              page:,
              per_page:,
              pages: (total.to_f / per_page).ceil
            }
          })
        end

        # GET /api/v1/flukebase_connect/batch/memories
        # Pull memories from multiple projects at once for local sync
        # Params: project_ids (array) or all=true, type (optional), since (optional)
        def batch_pull
          projects = resolve_batch_projects

          if projects.empty?
            return render_success({
              projects: [],
              meta: { count: 0, total_memories: 0 }
            })
          end

          project_ids = projects.map(&:id)

          # Build query for all memories across selected projects
          memories = ProjectMemory.where(project_id: project_ids)

          # Filter by type if specified
          memories = memories.where(memory_type: params[:type]) if params[:type].present?

          # Filter by tag if specified
          memories = memories.with_tag(params[:tag]) if params[:tag].present?

          # Filter by updated since timestamp (for incremental sync)
          memories = memories.since(Time.zone.parse(params[:since])) if params[:since].present?

          # Order by project then updated_at
          memories = memories.includes(:project).order(:project_id, updated_at: :desc)

          # Group memories by project
          grouped = memories.group_by(&:project_id)

          # Build response with project metadata
          project_data = projects.map do |project|
            project_memories = grouped[project.id] || []
            {
              project_id: project.id,
              project_name: project.name,
              memories: project_memories.map(&:to_api_hash),
              memories_count: project_memories.count
            }
          end

          render_success({
            projects: project_data,
            meta: {
              project_count: projects.count,
              total_memories: memories.count,
              type_filter: params[:type],
              since_filter: params[:since]
            }
          })
        end

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
              total:,
              page:,
              per_page:,
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
              memory = @project.project_memories.find_by(external_id:)

              if memory
                # Update existing
                if memory.update(memory_data.merge(synced_at: Time.current))
                  results[:updated] << memory.to_api_hash
                else
                  results[:errors] << { external_id:, errors: memory.errors.full_messages }
                end
              else
                # Create new
                memory = @project.project_memories.build(memory_data)
                memory.user = current_user
                memory.synced_at = Time.current

                if memory.save
                  results[:created] << memory.to_api_hash
                else
                  results[:errors] << { external_id:, errors: memory.errors.full_messages }
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

        # Validate memory_type param against allowed values
        def validate_memory_type_param
          return unless params[:type].present?

          unless VALID_MEMORY_TYPES.include?(params[:type])
            render_error(
              "Invalid memory type '#{params[:type]}'. Must be one of: #{VALID_MEMORY_TYPES.join(', ')}",
              status: :bad_request
            )
          end
        end

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
