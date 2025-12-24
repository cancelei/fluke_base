# Query object for searching and filtering time logs
# Uses Ransack for declarative filtering where applicable
class TimeLogsQuery
  def initialize(current_user, params = {})
    @current_user = current_user
    @params = normalize_params(params)
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
    project.time_logs
           .ransack(started_at_gteq: selected_date.beginning_of_day,
                    started_at_lteq: selected_date.end_of_day)
           .result
           .includes(:milestone)
           .order(started_at: :desc)
  end

  def filtered_time_logs(selected_project, selected_user, selected_date, projects, milestones)
    q = {
      started_at_gteq: selected_date.beginning_of_day,
      started_at_lteq: selected_date.end_of_day
    }
    q[:user_id_eq] = selected_user.id if selected_user.present?

    TimeLog.where(milestone: milestones)
           .ransack(q).result
           .includes(:milestone, :user)
           .order(started_at: :desc)
  end

  def milestones_pending_confirmation(milestones)
    milestones.includes(:time_logs)
              .where(status: "in_progress", time_logs: { status: "completed" })
  end

  def time_logs_completed(milestones, selected_date = Date.current)
    milestones.includes(:time_logs)
              .ransack(status_eq: Milestone::COMPLETED,
                       time_logs_status_eq: "completed",
                       time_logs_started_at_gteq: selected_date.beginning_of_day,
                       time_logs_started_at_lteq: selected_date.end_of_day)
              .result
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
    TimeLog.ransack(milestone_id_null: true, user_id_eq: user_id).result
  end

  def search_object(scope = TimeLog.all)
    scope.ransack(build_ransack_params)
  end

  private

  def normalize_params(params)
    hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    hash.with_indifferent_access
  end

  def build_ransack_params
    q = {}
    q[:user_id_eq] = @params[:user_id] if @params[:user_id].present?
    q[:milestone_id_eq] = @params[:milestone_id] if @params[:milestone_id].present?
    q[:project_id_eq] = @params[:project_id] if @params[:project_id].present?
    q[:status_eq] = @params[:status] if @params[:status].present?

    if @params[:date].present?
      date = Date.parse(@params[:date]) rescue Date.current
      q[:started_at_gteq] = date.beginning_of_day
      q[:started_at_lteq] = date.end_of_day
    end

    q
  end
end
