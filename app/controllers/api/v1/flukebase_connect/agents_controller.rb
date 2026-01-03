# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      # API controller for agent session management.
      # Provides registration, heartbeat, and discovery for flukebase_connect agents.
      #
      # Authentication: Bearer token with appropriate scopes
      # Required scopes:
      #   - read:agents for GET endpoints
      #   - write:agents for POST/PUT/DELETE endpoints
      class AgentsController < BaseController
        before_action :set_project
        before_action :set_agent, only: %i[show update destroy heartbeat]
        before_action -> { require_scope!("read:agents") }, only: %i[index show]
        before_action -> { require_scope!("write:agents") }, only: %i[register update destroy heartbeat]

        # GET /api/v1/flukebase_connect/projects/:project_id/agents
        # List all agent sessions for a project
        #
        # Query params:
        #   - status: Filter by status (active, idle, disconnected)
        #   - agent_type: Filter by agent type
        #   - connected_only: Only return connected agents (active/idle)
        #   - page, per_page: Pagination (max 100 per page)
        def index
          agents = @project.agent_sessions

          # Filters
          agents = agents.where(status: params[:status]) if params[:status].present?
          agents = agents.by_type(params[:agent_type]) if params[:agent_type].present?
          agents = agents.connected if params[:connected_only] == "true"
          agents = agents.with_persona if params[:with_persona] == "true"

          # Mark stale agents as idle before returning
          AgentSession.mark_stale_as_idle! if params[:refresh_status] == "true"

          # Ordering - most recently active first
          agents = agents.order(last_heartbeat_at: :desc)

          # Pagination
          page = (params[:page] || 1).to_i
          per_page = [(params[:per_page] || 50).to_i, 100].min
          total = agents.count
          agents = agents.offset((page - 1) * per_page).limit(per_page)

          render_success({
            agents: agents.map(&:to_api_hash),
            meta: {
              total:,
              page:,
              per_page:,
              pages: (total.to_f / per_page).ceil,
              active_count: @project.agent_sessions.active.count,
              connected_count: @project.agent_sessions.connected.count
            }
          })
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/agents/:id
        # Get a single agent session
        def show
          render_success({ agent: @agent.to_api_hash })
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/agents/register
        # Register or update an agent session
        #
        # Request body:
        #   {
        #     agent_id: "session-abc123",
        #     persona_name: "ZION",       # optional
        #     agent_type: "claude_code",  # optional
        #     capabilities: ["memory", "wedo"],  # optional
        #     client_version: "1.2.3",    # optional
        #     metadata: {}                # optional
        #   }
        def register
          agent = AgentSession.register!(
            project: @project,
            user: current_user,
            agent_id: register_params[:agent_id],
            persona_name: register_params[:persona_name],
            agent_type: register_params[:agent_type],
            capabilities: register_params[:capabilities],
            client_version: register_params[:client_version],
            metadata: register_params[:metadata],
            ip_address: request.remote_ip
          )

          # Broadcast agent registration via ActionCable if available
          broadcast_agent_event("agent.registered", agent)

          status = agent.previously_new_record? ? :created : :ok
          render_success({ agent: agent.to_api_hash }, status:)
        rescue ActiveRecord::RecordInvalid => e
          render_error("Failed to register agent", errors: e.record.errors.full_messages)
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/agents/:id/heartbeat
        # Update agent heartbeat
        #
        # Request body:
        #   {
        #     tokens_used: 100,     # optional - tokens used since last heartbeat
        #     tools_executed: 5,    # optional - tools executed since last heartbeat
        #     metadata: {}          # optional - additional metadata
        #   }
        def heartbeat
          @agent.heartbeat!(
            ip: request.remote_ip,
            metadata: params[:metadata]
          )

          # Update metrics if provided
          if params[:tokens_used].to_i.positive? || params[:tools_executed].to_i.positive?
            @agent.increment!(:tokens_used, params[:tokens_used].to_i)
            @agent.increment!(:tools_executed, params[:tools_executed].to_i)
          end

          render_success({
            agent: @agent.to_api_hash,
            server_time: Time.current.iso8601
          })
        end

        # PUT /api/v1/flukebase_connect/projects/:project_id/agents/:id
        # Update agent metadata
        def update
          if @agent.update(update_params)
            broadcast_agent_event("agent.updated", @agent)
            render_success({ agent: @agent.to_api_hash })
          else
            render_error("Failed to update agent", errors: @agent.errors.full_messages)
          end
        end

        # DELETE /api/v1/flukebase_connect/projects/:project_id/agents/:id
        # Disconnect/remove an agent session
        def destroy
          if params[:hard_delete] == "true"
            @agent.destroy!
            render_success({ deleted: true, agent_id: @agent.agent_id })
          else
            @agent.disconnect!
            broadcast_agent_event("agent.disconnected", @agent)
            render_success({ agent: @agent.to_api_hash })
          end
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/agents/whoami
        # Get current agent session based on agent_id header
        def whoami
          agent_id = request.headers["X-Agent-ID"] || params[:agent_id]

          if agent_id.blank?
            return render_error("X-Agent-ID header or agent_id parameter required", status: :bad_request)
          end

          agent = @project.agent_sessions.find_by(agent_id:)

          if agent
            render_success({ agent: agent.to_api_hash })
          else
            render_success({ agent: nil, registered: false })
          end
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/agents/cleanup
        # Clean up stale/disconnected sessions
        def cleanup
          # Mark stale as idle
          stale_count = @project.agent_sessions.stale.count
          AgentSession.mark_stale_as_idle!

          # Disconnect long-idle sessions
          disconnected_count = 0
          if params[:disconnect_stale] == "true"
            to_disconnect = @project.agent_sessions.idle.where("last_heartbeat_at < ?", 10.minutes.ago)
            disconnected_count = to_disconnect.count
            to_disconnect.find_each(&:disconnect!)
          end

          # Hard delete old disconnected sessions
          deleted_count = 0
          if params[:delete_disconnected] == "true"
            old_cutoff = (params[:older_than_hours] || 24).to_i.hours.ago
            to_delete = @project.agent_sessions.disconnected.where("disconnected_at < ?", old_cutoff)
            deleted_count = to_delete.count
            to_delete.destroy_all
          end

          render_success({
            cleanup_results: {
              marked_idle: stale_count,
              disconnected: disconnected_count,
              deleted: deleted_count
            }
          })
        end

        private

        def set_project
          project_id = params[:project_id].to_i
          @project = current_user.accessible_projects.find { |p| p.id == project_id }
          forbidden unless @project
        end

        def set_agent
          # Support lookup by agent_id or database id
          @agent = @project.agent_sessions.find_by(agent_id: params[:id]) ||
                   @project.agent_sessions.find_by(id: params[:id])

          not_found unless @agent
        end

        def register_params
          params.require(:agent).permit(
            :agent_id, :persona_name, :agent_type, :client_version,
            capabilities: [], metadata: {}
          )
        end

        def update_params
          params.require(:agent).permit(
            :persona_name, :agent_type, :client_version, :status,
            capabilities: [], metadata: {}
          )
        end

        def broadcast_agent_event(event_type, agent)
          return unless defined?(TeamBoardChannel)

          TeamBoardChannel.broadcast_to(
            @project,
            {
              type: event_type,
              agent: agent.to_api_hash,
              timestamp: Time.current.iso8601
            }
          )
        rescue StandardError => e
          Rails.logger.warn "[AgentsController] Broadcast failed: #{e.message}"
        end
      end
    end
  end
end
