class TimeLogsQuery
  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def milestones_for_project(project)
    owner = @current_user.id == project.user_id

    if owner
      project.milestones
    else
      milestone_ids = project.agreements
                            .joins(:agreement_participants)
                            .where(agreement_participants: { user_id: @current_user.id })
                            .pluck(:milestone_ids)
                            .flatten
      Milestone.where(id: milestone_ids)
    end
  end

  def time_logs_for_project(project, selected_date = Date.current)
    date_range = selected_date.beginning_of_day..selected_date.end_of_day

    project.time_logs
           .includes(:milestone)
           .where(started_at: date_range)
           .order(started_at: :desc)
  end

  def filtered_time_logs(selected_project, selected_user, selected_date, projects, milestones)
    date_range = selected_date.beginning_of_day..selected_date.end_of_day

    logs = TimeLog.where(milestone: milestones)
    logs = logs.where(user_id: selected_user.id) if selected_user.present?
    logs = logs.includes(:milestone, :user)
               .where(started_at: date_range)
               .order(started_at: :desc)
    logs
  end

  def milestones_pending_confirmation(milestones)
    milestones.includes(:time_logs)
              .where(status: "in_progress", time_logs: { status: "completed" })
  end

  def time_logs_completed(milestones, selected_date = Date.current)
    date_range = selected_date.beginning_of_day..selected_date.end_of_day

    milestones.includes(:time_logs)
              .where(status: Milestone::COMPLETED, time_logs: { status: "completed" })
              .where(time_logs: { started_at: date_range })
  end

  def projects_for_filter
    Project.where(id: @current_user.projects.ids + @current_user.mentor_projects.ids)
  end

  def users_for_filter(milestones)
    User.joins(:time_logs)
        .where(time_logs: { milestone_id: milestones.ids })
        .distinct
  end

  def manual_time_logs(selected_user = nil)
    user_id = selected_user&.id || @current_user.id
    TimeLog.where(milestone_id: nil, user_id: user_id)
  end
end
