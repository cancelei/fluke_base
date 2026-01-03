# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      # API controller for WeDo task management.
      # Provides CRUD operations and bulk sync for the Team Board.
      #
      # Authentication: Bearer token with appropriate scopes
      # Required scopes:
      #   - read:tasks for GET endpoints
      #   - write:tasks for POST/PUT/DELETE endpoints
      class WedoTasksController < BaseController
        before_action :set_project
        before_action :set_task, only: %i[show update destroy]
        before_action -> { require_scope!("read:tasks") }, only: %i[index show]
        before_action -> { require_scope!("write:tasks") }, only: %i[create update destroy bulk_sync]

        # GET /api/v1/flukebase_connect/projects/:project_id/wedo_tasks
        # List tasks with optional filters
        #
        # Query params:
        #   - status: Filter by status (pending, in_progress, completed, blocked)
        #   - scope: Filter by scope (default: global)
        #   - assignee_id: Filter by assignee
        #   - root_only: Only return tasks without parent (true/false)
        #   - since_version: Only return tasks with version > N
        #   - page, per_page: Pagination (max 100 per page)
        def index
          tasks = @project.wedo_tasks

          # Filters
          tasks = tasks.where(status: params[:status]) if params[:status].present?
          tasks = tasks.for_scope(params[:scope]) if params[:scope].present?
          tasks = tasks.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?
          tasks = tasks.root_tasks if params[:root_only] == "true"

          # Incremental sync support
          since_version = params[:since_version].to_i
          tasks = tasks.since_version(since_version) if since_version.positive?

          # Ordering
          tasks = tasks.by_priority.order(updated_at: :desc)

          # Pagination
          page = (params[:page] || 1).to_i
          per_page = [(params[:per_page] || 50).to_i, 100].min
          total = tasks.count
          tasks = tasks.offset((page - 1) * per_page).limit(per_page)

          render_success({
            tasks: tasks.map(&:to_api_hash),
            meta: {
              total: total,
              page: page,
              per_page: per_page,
              pages: (total.to_f / per_page).ceil,
              max_version: @project.wedo_tasks.maximum(:version) || 0
            }
          })
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/wedo_tasks/:id
        # Get a single task by task_id or database id
        def show
          render_success({ task: @task.to_api_hash(include_subtasks: true) })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/wedo_tasks
        # Create a new task
        def create
          task = @project.wedo_tasks.build(task_create_params)
          task.created_by = current_user
          task.updated_by = current_user

          # Handle parent task by task_id
          if params.dig(:task, :parent_task_id).present?
            parent = @project.wedo_tasks.find_by(task_id: params[:task][:parent_task_id])
            task.parent_task = parent
          end

          # Initialize synthesis report
          task.append_synthesis_note("Task created", agent_id: params.dig(:task, :agent_id))

          if task.save
            render_success({ task: task.to_api_hash }, status: :created)
          else
            render_error("Failed to create task", errors: task.errors.full_messages)
          end
        end

        # PUT /api/v1/flukebase_connect/projects/:project_id/wedo_tasks/:id
        # Update a task with optimistic locking
        def update
          # Optimistic locking via version
          client_version = params.dig(:task, :version).to_i

          if client_version.positive? && @task.version > client_version
            # Conflict detected - return 409 with server state
            return render_conflict(@task, client_version)
          end

          @task.updated_by = current_user

          # Append synthesis note if provided
          if params.dig(:task, :synthesis_note).present?
            agent_id = params.dig(:task, :agent_id)
            @task.append_synthesis_note(params[:task][:synthesis_note], agent_id: agent_id)
          end

          if @task.update(task_update_params)
            render_success({ task: @task.to_api_hash })
          else
            render_error("Failed to update task", errors: @task.errors.full_messages)
          end
        end

        # DELETE /api/v1/flukebase_connect/projects/:project_id/wedo_tasks/:id
        # Delete a task
        def destroy
          task_id = @task.task_id
          @task.destroy!
          render_success({ deleted: true, task_id: task_id })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/wedo_tasks/bulk_sync
        # Bulk sync tasks from CLI with conflict detection
        #
        # Request body:
        #   { tasks: [{ external_id, task_id, description, status, ... }] }
        #
        # Response:
        #   { sync_results: { created: [], updated: [], conflicts: [], errors: [] } }
        def bulk_sync
          results = { created: [], updated: [], conflicts: [], errors: [] }

          tasks_data = params.require(:tasks)

          tasks_data.each do |task_data|
            sync_single_task(task_data, results)
          end

          render_success({
            sync_results: results,
            summary: {
              created: results[:created].count,
              updated: results[:updated].count,
              conflicts: results[:conflicts].count,
              errors: results[:errors].count
            },
            max_version: @project.wedo_tasks.maximum(:version) || 0
          })
        end

        private

        def set_project
          project_id = params[:project_id].to_i
          @project = current_user.accessible_projects.find { |p| p.id == project_id }
          forbidden unless @project
        end

        def set_task
          # Support lookup by task_id or database id
          @task = @project.wedo_tasks.find_by(task_id: params[:id]) ||
                  @project.wedo_tasks.find_by(id: params[:id])

          not_found unless @task
        end

        def task_create_params
          params.require(:task).permit(
            :task_id, :description, :status, :dependency, :scope, :priority,
            :artifact_path, :remote_url, :template_id, :assignee_id, :due_date,
            :external_id,
            blocked_by: [], tags: []
          )
        end

        def task_update_params
          params.require(:task).permit(
            :description, :status, :dependency, :scope, :priority,
            :artifact_path, :remote_url, :assignee_id, :due_date,
            blocked_by: [], tags: []
          )
        end

        def render_conflict(task, client_version)
          render json: {
            error: "conflict",
            message: "Task has been modified. Your version: #{client_version}, Server version: #{task.version}",
            server_task: task.to_api_hash
          }, status: :conflict
        end

        def sync_single_task(task_data, results)
          task_data = task_data.permit(
            :external_id, :task_id, :description, :status, :dependency,
            :scope, :priority, :synthesis_report, :artifact_path,
            :remote_url, :completed_at, :template_id, :parent_task_id,
            :version, :agent_id,
            blocked_by: [], tags: []
          )

          external_id = task_data[:external_id]
          task_id = task_data[:task_id]

          # Find existing task by external_id or task_id
          existing = @project.wedo_tasks.find_by(external_id: external_id) if external_id.present?
          existing ||= @project.wedo_tasks.find_by(task_id: task_id) if task_id.present?

          if existing
            sync_existing_task(existing, task_data, results)
          else
            create_synced_task(task_data, results)
          end
        rescue StandardError => e
          results[:errors] << { external_id: task_data[:external_id], error: e.message }
        end

        def sync_existing_task(existing, task_data, results)
          client_version = task_data[:version].to_i

          if client_version.positive? && existing.version > client_version
            # Conflict - merge and log
            merged_task = merge_task_with_conflict(existing, task_data)
            results[:conflicts] << merged_task.to_api_hash
          else
            # Normal update
            update_attrs = task_data.except(:external_id, :version, :agent_id, :task_id)
            if existing.update(update_attrs)
              results[:updated] << existing.to_api_hash
            else
              results[:errors] << {
                external_id: task_data[:external_id],
                errors: existing.errors.full_messages
              }
            end
          end
        end

        def create_synced_task(task_data, results)
          task = @project.wedo_tasks.build(task_data.except(:version, :agent_id))
          task.created_by = current_user
          task.updated_by = current_user

          # Handle parent task by task_id
          if task_data[:parent_task_id].present?
            parent = @project.wedo_tasks.find_by(task_id: task_data[:parent_task_id])
            task.parent_task = parent
          end

          if task.save
            results[:created] << task.to_api_hash
          else
            results[:errors] << {
              external_id: task_data[:external_id],
              errors: task.errors.full_messages
            }
          end
        end

        def merge_task_with_conflict(existing, incoming)
          # Merge strategy: server wins, log conflict in synthesis_report
          conflict_note = "CONFLICT: Local changes attempted with version #{incoming[:version]}, " \
                          "server at version #{existing.version}. Incoming: " \
                          "status=#{incoming[:status]}, desc=#{incoming[:description]&.truncate(50)}"

          existing.append_synthesis_note(conflict_note, agent_id: incoming[:agent_id])
          existing.save!
          existing
        end
      end
    end
  end
end
