# frozen_string_literal: true

module FlukebaseConnect
  # Coordinates smart delegation of WeDo tasks to container sessions.
  #
  # Responsibilities:
  # - Process pending delegable tasks and assign to available sessions
  # - Handle context threshold events and trigger handoffs
  # - Manage session lifecycle for delegation purposes
  # - Broadcast delegation events for real-time updates
  #
  # Usage:
  #   service = FlukebaseConnect::DelegationCoordinatorService.new(project)
  #   service.process_pending_delegations
  #   service.handle_threshold_reached(session)
  #
  class DelegationCoordinatorService
    attr_reader :project, :pool

    def initialize(project)
      @project = project
      @pool = project.container_pool
    end

    # Process pending delegable tasks and assign to available sessions
    # @param limit [Integer] Maximum tasks to process (default: 10)
    # @return [Hash] Results summary
    def process_pending_delegations(limit: 10)
      return { error: "No container pool configured" } unless pool
      return { error: "Pool is paused" } unless pool.active?
      return { error: "Auto-delegation disabled" } unless pool.auto_delegate_enabled

      results = { delegated: [], skipped: [], no_session: [] }

      pending_delegable_tasks(limit:).each do |task|
        result = delegate_task(task)
        case result[:status]
        when :delegated
          results[:delegated] << result
        when :skipped
          results[:skipped] << result
        when :no_session
          results[:no_session] << result
          break # No point continuing if no sessions available
        end
      end

      results
    end

    # Delegate a single task to an available session
    # @param task [WedoTask] The task to delegate
    # @return [Hash] Delegation result
    def delegate_task(task)
      # Skip USER_REQUIRED if configured
      if task.dependency == "USER_REQUIRED" && pool.skip_user_required
        return { status: :skipped, task_id: task.task_id, reason: "USER_REQUIRED" }
      end

      # Find available session with context capacity
      session = pool.find_available_session

      unless session
        # Check if we can spawn a new session
        if pool.can_spawn_new_session?
          return { status: :no_session, task_id: task.task_id, reason: "spawn_needed" }
        end
        return { status: :no_session, task_id: task.task_id, reason: "pool_exhausted" }
      end

      # Attempt atomic claim
      request = DelegationRequest.atomic_claim(task, session)

      if request
        broadcast_event("delegation.auto_assigned", {
          task_id: task.task_id,
          session_id: session.session_id,
          context_before: session.context_percent
        })

        { status: :delegated, task_id: task.task_id, session_id: session.session_id }
      else
        { status: :skipped, task_id: task.task_id, reason: "claim_failed" }
      end
    end

    # Handle context threshold reached event
    # @param session [ContainerSession] The session at threshold
    # @return [Hash] Handoff instructions
    def handle_threshold_reached(session)
      # Mark session for handoff
      session.mark_handoff_pending!

      # Broadcast handoff needed
      broadcast_event("session.handoff_needed", {
        session_id: session.session_id,
        context_percent: session.context_percent,
        current_task: session.current_task_id
      })

      # Generate handoff instructions
      {
        action: "handoff",
        session_id: session.session_id,
        current_task: session.current_task_id,
        context_percent: session.context_percent,
        summary_prompt: build_summary_prompt(session),
        pending_tasks: pending_tasks_for_reassignment
      }
    end

    # Complete a delegation when task is done
    # @param task [WedoTask] The completed task
    # @return [Boolean] Success
    def complete_delegation(task)
      request = DelegationRequest.find_by(wedo_task: task, status: "claimed")
      return false unless request

      request.complete!

      broadcast_event("delegation.completed", {
        task_id: task.task_id,
        session_id: request.container_session&.session_id
      })

      true
    end

    # Find session with most context capacity for optimal task assignment
    # @return [ContainerSession, nil]
    def optimal_session_for_new_task
      pool&.container_sessions
        &.available
        &.where("context_percent < ?", pool.context_threshold_percent - 20)
        &.order(:context_percent)
        &.first
    end

    # Get delegation statistics for the project
    # @return [Hash] Statistics
    def stats
      return {} unless pool

      agent_tasks = project.wedo_tasks.where(dependency: "AGENT_CAPABLE")
      delegations = DelegationRequest.where(project: project)

      {
        pool_status: pool.status,
        active_sessions: pool.active_session_count,
        idle_sessions: pool.idle_session_count,
        total_tasks: project.wedo_tasks.count,
        agent_capable: agent_tasks.count,
        pending_delegable: pending_delegable_tasks.count,
        total_delegations: delegations.count,
        completed_delegations: delegations.completed.count,
        active_delegations: delegations.active.count,
        avg_tasks_per_session: calculate_avg_tasks_per_session
      }
    end

    private

    def pending_delegable_tasks(limit: 10)
      project.wedo_tasks
        .pending
        .where(dependency: "AGENT_CAPABLE")
        .where.not(id: DelegationRequest.claimed.select(:wedo_task_id))
        .by_priority
        .limit(limit)
    end

    def pending_tasks_for_reassignment
      pending_delegable_tasks(limit: 5).map do |task|
        { task_id: task.task_id, priority: task.priority, description: task.description.truncate(100) }
      end
    end

    def build_summary_prompt(session)
      <<~PROMPT
        Generate a concise handoff summary for session transfer. Include:

        1. **Current Task Status**: #{session.current_task_id || 'None'}
           - What has been completed
           - Current progress point

        2. **Context Used**: #{session.context_percent.round(1)}%
           - Key decisions made during this session
           - Important discoveries or blockers encountered

        3. **Recommended Next Steps**:
           - Immediate actions for the next session
           - Any pending items that need attention

        Keep the summary under 500 words to preserve context in the new session.
      PROMPT
    end

    def calculate_avg_tasks_per_session
      completed_sessions = pool.container_sessions.where(status: "retired")
      return 0 if completed_sessions.empty?

      total_tasks = completed_sessions.sum(:tasks_completed)
      (total_tasks.to_f / completed_sessions.count).round(2)
    end

    def broadcast_event(event_type, data)
      TeamBoardChannel.broadcast_to(project, {
        type: event_type,
        data: data,
        timestamp: Time.current.iso8601
      })
    end
  end
end
