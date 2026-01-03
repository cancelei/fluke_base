# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      # API controller for smart delegation coordination.
      # Manages project-scoped container pools, session tracking,
      # and context-aware task delegation.
      #
      # Authentication: Bearer token with appropriate scopes
      # Required scopes:
      #   - read:delegation for GET endpoints
      #   - write:delegation for POST endpoints
      class DelegationController < BaseController
        before_action :set_project
        before_action :ensure_pool_exists, except: [:create_pool]
        before_action -> { require_scope!("read:delegation") }, only: %i[status next_task]
        before_action -> { require_scope!("write:delegation") }, only: %i[create_pool claim report_context handoff register_session]

        # GET /api/v1/flukebase_connect/projects/:project_id/delegation/status
        # Get delegation status including pool, sessions, and pending tasks
        def status
          render_success({
            pool: @pool.to_api_hash,
            sessions: @pool.container_sessions.active.map(&:to_api_hash),
            pending_tasks: pending_delegable_tasks,
            active_delegations: active_delegations,
            stats: delegation_stats
          })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/delegation/pool
        # Create or update the container pool for a project
        def create_pool
          @pool = @project.container_pool || @project.build_container_pool

          pool_params = params.permit(
            :warm_pool_size, :max_pool_size, :context_threshold_percent,
            :auto_delegate_enabled, :skip_user_required, config: {}
          )

          if @pool.update(pool_params)
            render_success({ pool: @pool.to_api_hash })
          else
            render_error("Failed to configure pool", errors: @pool.errors.full_messages)
          end
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/delegation/claim
        # Atomically claim a task for a session (prevents double-delegation)
        def claim
          task = @project.wedo_tasks.find_by!(task_id: params[:task_id])
          session = @pool.container_sessions.find_by!(session_id: params[:session_id])

          # Validate task is delegable
          unless task.dependency == "AGENT_CAPABLE"
            return render_error("Task requires user input", code: "user_required")
          end

          unless task.status == "pending"
            return render_error("Task is not pending", code: "not_pending")
          end

          # Attempt atomic claim
          request = DelegationRequest.atomic_claim(task, session)

          if request
            broadcast_delegation_event("delegation.claimed", {
              task_id: task.task_id,
              session_id: session.session_id
            })
            render_success({ claimed: true, task: task.reload.to_api_hash, delegation: request.to_api_hash })
          else
            render_error("Task already claimed by another session", code: "already_claimed", status: :conflict)
          end
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/delegation/report_context
        # Report context usage for a session and get recommendations
        def report_context
          session = @pool.container_sessions.find_by!(session_id: params[:session_id])

          action_result = session.update_context_usage!(
            used: params[:used_tokens].to_i,
            max: params[:max_tokens].to_i
          )

          # Broadcast if threshold reached
          if action_result[:action] == "handoff_required"
            broadcast_delegation_event("session.threshold_reached", {
              session_id: session.session_id,
              context_percent: session.context_percent
            })
          end

          render_success({
            updated: true,
            session: session.to_api_hash,
            action: action_result[:action],
            reason: action_result[:reason]
          })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/delegation/handoff
        # Record a session handoff when context is full
        def handoff
          old_session = @pool.container_sessions.find_by!(session_id: params[:old_session_id])

          # Create new session record
          new_session = @pool.container_sessions.create!(
            session_id: params[:new_session_id],
            container_id: params[:container_id],
            status: "starting",
            handoff_from: old_session,
            handoff_summary: params[:summary]
          )

          # Retire old session
          old_session.retire!(summary: params[:summary])

          broadcast_delegation_event("session.handoff", {
            old_session_id: old_session.session_id,
            new_session_id: new_session.session_id,
            context_at_handoff: old_session.context_percent
          })

          render_success({
            handoff: true,
            old_session: old_session.to_api_hash,
            new_session: new_session.to_api_hash
          })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/delegation/register_session
        # Register a new container session for delegation
        def register_session
          session = @pool.container_sessions.find_or_initialize_by(session_id: params[:session_id])

          session_params = params.permit(:container_id, :status, metadata: {})
          session.assign_attributes(session_params)
          session.last_activity_at = Time.current

          # Link to agent session if provided
          if params[:agent_session_id].present?
            agent_session = @project.agent_sessions.find_by(id: params[:agent_session_id])
            session.agent_session = agent_session if agent_session
          end

          if session.save
            broadcast_delegation_event("session.registered", {
              session_id: session.session_id,
              status: session.status
            })
            render_success({ session: session.to_api_hash })
          else
            render_error("Failed to register session", errors: session.errors.full_messages)
          end
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/delegation/next_task
        # Get next delegable task (AGENT_CAPABLE, pending, not claimed)
        def next_task
          task = @project.wedo_tasks
            .pending
            .where(dependency: "AGENT_CAPABLE")
            .where.not(id: DelegationRequest.claimed.select(:wedo_task_id))
            .by_priority
            .first

          if task
            render_success({ task: task.to_api_hash })
          else
            render_success({ task: nil, message: "No delegable tasks available" })
          end
        end

        private

        def set_project
          project_id = params[:project_id].to_i
          @project = current_user.accessible_projects.find { |p| p.id == project_id }
          forbidden unless @project
        end

        def ensure_pool_exists
          @pool = @project.container_pool

          unless @pool
            render json: {
              error: "no_pool",
              message: "No container pool configured for this project. Create one first.",
              create_pool_url: api_v1_flukebase_connect_project_delegation_create_pool_path(@project)
            }, status: :not_found
          end
        end

        def pending_delegable_tasks
          @project.wedo_tasks
            .pending
            .where(dependency: "AGENT_CAPABLE")
            .where.not(id: DelegationRequest.claimed.select(:wedo_task_id))
            .by_priority
            .limit(10)
            .map(&:to_api_hash)
        end

        def active_delegations
          DelegationRequest
            .joins(:wedo_task)
            .where(wedo_tasks: { project_id: @project.id })
            .active
            .includes(:wedo_task, :container_session)
            .map(&:to_api_hash)
        end

        def delegation_stats
          tasks = @project.wedo_tasks
          agent_capable = tasks.where(dependency: "AGENT_CAPABLE")

          {
            total_tasks: tasks.count,
            agent_capable_tasks: agent_capable.count,
            pending_delegable: agent_capable.pending.count,
            active_sessions: @pool.active_session_count,
            idle_sessions: @pool.idle_session_count,
            total_delegations: DelegationRequest.where(project: @project).count,
            completed_delegations: DelegationRequest.where(project: @project).completed.count
          }
        end

        def broadcast_delegation_event(event_type, data)
          TeamBoardChannel.broadcast_to(@project, {
            type: event_type,
            data: data,
            timestamp: Time.current.iso8601
          })
        end
      end
    end
  end
end
