class TimeLogsController < ApplicationController
  include ResultHandling

  before_action :authenticate_user!
  before_action :set_project, except: [ :filter ]
  before_action :set_milestone, only: [ :create, :stop_tracking ]
  before_action :set_time_log, only: [ :stop_tracking ]
  before_action :set_manual_time_log, only: [ :index ]
  before_action :ensure_no_active_time_log, only: [ :create_manual, :create ]

  def create_manual
    # Check if milestone_id is provided
    if params[:time_log][:milestone_id].blank?
              respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update("flash_messages",
              partial: "shared/flash_messages",
              locals: { alert: "Please select a milestone before adding a manual time log." }
            )
          end
        format.html { redirect_to time_logs_path(@project), alert: "Please select a milestone before adding a manual time log." }
      end
      return
    end

    # Find the milestone
    @milestone = @project.milestones.find_by(id: params[:time_log][:milestone_id])
    if @milestone.nil?
              respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update("flash_messages",
              partial: "shared/flash_messages",
              locals: { alert: "Milestone not found. Please select a valid milestone." }
            )
          end
        format.html { redirect_to time_logs_path(@project), alert: "Milestone not found. Please select a valid milestone." }
      end
      return
    end

    @time_log = @project.time_logs.new(time_log_params)
    @time_log.user = current_user
    @time_log.status = "completed"

    if @time_log.save
      @milestone.update(status: "in_progress")

      # Reload data for updated views
      reload_data_for_views

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("manual_time_log_form",
              partial: "time_logs/manual_form",
              locals: { time_log_manual: TimeLog.new, milestones: @milestones }
            ),
            turbo_stream.replace("milestone_#{@milestone.id}",
              partial: "time_logs/milestone_row",
              locals: { milestone: @milestone, project: @project, active_log: nil }
            ),
            turbo_stream.update("pending_confirmation_section",
              partial: "time_logs/pending_confirmation_section",
              locals: {
                milestones_pending_confirmation: @milestones_pending_confirmation,
                project: @project,
                owner: @owner
              }
            ),
            turbo_stream.update("remaining_time_progress",
              partial: "remaining_time_progress",
              locals: { project: @project, current_log: nil, owner: @owner, project_wide: true }
            ),
                        turbo_stream.update("flash_messages",
              partial: "shared/flash_messages",
              locals: { notice: "Time log created successfully." }
            )
          ]
        end
        format.html { redirect_to time_logs_path(@project), notice: "Time log created successfully." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("manual_time_log_form",
              partial: "time_logs/manual_form",
              locals: { time_log_manual: @time_log, milestones: @milestones }
            ),
                        turbo_stream.update("flash_messages",
              partial: "shared/flash_messages",
              locals: { alert: @time_log.errors.full_messages.to_sentence }
            )
          ]
        end
        format.html { redirect_to time_logs_path(@project), alert: @time_log.errors.full_messages.to_sentence }
      end
    end
  end

  def index
    @owner = current_user.id == @project.user_id

    # Get milestones for the current project's project
    @milestones = (@owner ? @project.milestones : Milestone.where(id: @project.agreements.joins(:agreement_participants).where(agreement_participants: { user_id: current_user.id }).pluck(:milestone_ids).flatten))

    # Get all time logs for the project
    @time_logs = @project.time_logs
                           .includes(:milestone)
                           .order(started_at: :desc)

    @milestones_pending_confirmation = @milestones
                                         .includes(:time_logs)
                                         .where(status: "in_progress", time_logs: { status: "completed" })
    @time_logs_completed = @milestones
                            .includes(:time_logs)
                            .where(status: Milestone::COMPLETED, time_logs: { status: "completed" })

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("milestones_section",
            partial: "time_logs/milestones_section",
            locals: { milestones: @milestones, project: @project }
          ),
          turbo_stream.update("pending_confirmation_section",
            partial: "time_logs/pending_confirmation_section",
            locals: {
              milestones_pending_confirmation: @milestones_pending_confirmation,
              project: @project,
              owner: @owner
            }
          ),
          turbo_stream.update("completed_tasks_section",
            partial: "time_logs/completed_tasks_section",
            locals: {
              time_logs_completed: @time_logs_completed,
              project: @project,
              owner: @owner
            }
          ),
          turbo_stream.update("remaining_time_progress",
            partial: "remaining_time_progress",
            locals: { project: @project, current_log: current_tracking_log, owner: @owner, project_wide: true }
          )
        ]
      end
    end
  end

  def create
    @time_log = @project.time_logs.new(
      milestone: @milestone,
      started_at: Time.current,
      status: "in_progress",
      user: current_user
    )

    if @time_log.save
      if current_user.respond_to?(:multi_project_tracking) && current_user.multi_project_tracking
        session[:progress_milestone_ids] ||= {}
        session[:progress_milestone_ids][@project.id] = @time_log.milestone_id
      else
        session[:progress_milestone_id] = @time_log.milestone_id
      end
      @milestone.update(status: "in_progress")

      # Reload data for updated views
      reload_data_for_views

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("milestone_#{@milestone.id}",
              partial: "time_logs/milestone_row",
              locals: { milestone: @milestone, project: @project, active_log: @time_log }
            ),
                                    turbo_stream.update("current_tracking_container",
              partial: "time_logs/current_tracking",
              locals: { current_log: @time_log, project: @project }
            ),
            turbo_stream.update("milestone_bar_container",
              partial: "shared/milestone_bar"
            ),
            turbo_stream.update("navbar_milestones_list",
              partial: "shared/navbar_milestones_list"
            ),
            turbo_stream.update("remaining_time_progress",
              partial: "remaining_time_progress",
              locals: { project: @project, current_log: @time_log, owner: @owner }
            ),
                        turbo_stream.update("flash_messages",
              partial: "shared/flash_messages",
              locals: { notice: "Started tracking time for this milestone." }
            )
          ]
        end
        format.html { redirect_to time_logs_path(@project), notice: "Started tracking time for this milestone." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash_messages",
            partial: "shared/flash_messages",
            locals: { alert: @time_log.errors.full_messages.to_sentence }
          )
        end
        format.html { redirect_to time_logs_path(@project), alert: @time_log.errors.full_messages.to_sentence }
      end
    end
  end

  def stop_tracking
    if @time_log.complete!
      if current_user.respond_to?(:multi_project_tracking) && current_user.multi_project_tracking
        if session[:progress_milestone_ids].is_a?(Hash)
          session[:progress_milestone_ids].delete(@project.id)
        end
      else
        session[:progress_milestone_id] = nil
      end

      # Reload data for updated views
      reload_data_for_views

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("milestone_#{@time_log.milestone_id}",
              partial: "time_logs/milestone_row",
              locals: { milestone: @time_log.milestone, project: @project, active_log: nil }
            ),
                        turbo_stream.update("current_tracking_container", ""),
            turbo_stream.update("milestone_bar_container",
              partial: "shared/milestone_bar"
            ),
            turbo_stream.update("navbar_milestones_list",
              partial: "shared/navbar_milestones_list"
            ),
            turbo_stream.update("pending_confirmation_section",
              partial: "time_logs/pending_confirmation_section",
              locals: {
                milestones_pending_confirmation: @milestones_pending_confirmation,
                project: @project,
                owner: @owner
              }
            ),
            turbo_stream.update("remaining_time_progress",
              partial: "remaining_time_progress",
              locals: { project: @project, current_log: nil, owner: @owner, project_wide: true }
            ),
                        turbo_stream.update("flash_messages",
              partial: "shared/flash_messages",
              locals: { notice: "Stopped tracking time." }
            )
          ]
        end
        format.html { redirect_to time_logs_path(@project), notice: "Stopped tracking time." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash_messages",
            partial: "shared/flash_messages",
            locals: { alert: @time_log.errors.full_messages.to_sentence }
          )
        end
        format.html { redirect_to time_logs_path(@project), alert: @time_log.errors.full_messages.to_sentence }
      end
    end
  end

  def filter
    @selected_project = Project.find_by(id: params[:project_id])
    @selected_user = User.find_by(id: params[:user_id])
    # Set the selected date or default to today
    @selected_date = params[:date].present? ? Date.parse(params[:date]) : Date.current

    # Get the date range for the carousel (3 days before and after selected date)
    @date_range = (@selected_date - 3.days)..(@selected_date + 3.days)

    @projects = Project.where(id: current_user.projects.ids + current_user.mentor_projects.ids)
    @milestones = Milestone.where(project_id: @selected_project&.id || @projects.ids)
    @users = User.joins(:time_logs).where(time_logs: { milestone_id: @milestones.ids }).distinct

    @time_logs = TimeLog.where(milestone: @milestones)
    @time_logs = @time_logs.where(user_id: @selected_user.id) if @selected_user.present?
    @time_logs = @time_logs.includes(:milestone, :user)
                           .where("DATE(started_at) = '#{@selected_date}'")
                           .order(started_at: :desc)

    @milestones_pending_confirmation = @milestones
                                         .includes(:time_logs)
                                         .where(status: "in_progress", time_logs: { status: "completed" })
    @time_logs_completed = @milestones
                            .includes(:time_logs)
                            .where(status: "completed", time_logs: { status: "completed" })
                            .where("DATE(time_logs.started_at) = ?", @selected_date)

    @time_logs_manual = TimeLog.where(milestone_id: nil, user_id: @selected_user&.id || current_user.id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("filter_results",
            partial: "time_logs/filter_results",
            locals: {
              time_logs: @time_logs,
              milestones_pending_confirmation: @milestones_pending_confirmation,
              time_logs_completed: @time_logs_completed,
              time_logs_manual: @time_logs_manual,
              selected_date: @selected_date,
              selected_project: @selected_project,
              selected_user: @selected_user
            }
          )
        ]
      end
      format.html
    end
  end

  private

  def time_log_params
    params.require(:time_log).permit(:started_at, :ended_at, :description, :milestone_id, :manual_entry)
  end

  def ensure_no_active_time_log
    if time_log_in_progress
      respond_to do |format|
        format.turbo_stream do
                    render turbo_stream: turbo_stream.update("flash_messages",
            partial: "shared/flash_messages",
            locals: { alert: "You already have a time log in progress." }
          )
        end
        format.html { redirect_to time_logs_path(@project), alert: "You already have a time log in progress." }
      end
    end
  end

  def set_manual_time_log
    @time_log_manual = TimeLog.new
  end

  def set_project
    # Check if user is either the mentor or entrepreneur in the project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "project not found or access denied."
  end

  def set_milestone
    @milestone = @project.milestones.find(params[:milestone_id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream do
                render turbo_stream: turbo_stream.update("flash_messages",
          partial: "shared/flash_messages",
          locals: { alert: "Milestone not found." }
        )
      end
      format.html { redirect_to time_logs_path(@project), alert: "Milestone not found." }
    end
  end

  def set_time_log
    @time_log = @project.time_logs.in_progress.find_by(milestone: @milestone)
    return if @time_log.present?

    respond_to do |format|
      format.turbo_stream do
                render turbo_stream: turbo_stream.update("flash_messages",
          partial: "shared/flash_messages",
          locals: { alert: "No active time log found for this milestone." }
        )
      end
      format.html { redirect_to time_logs_path(@project), alert: "No active time log found for this milestone." }
    end
  end

  def time_log_in_progress
    scope = TimeLog.in_progress.where(user_id: current_user.id)
    if current_user.respond_to?(:multi_project_tracking) && current_user.multi_project_tracking
      scope = scope.where(project_id: @project.id)
    end
    scope.exists?
  end

  def current_tracking_log
    @project.time_logs.where(user_id: current_user.id).in_progress.last
  end

  def reload_data_for_views
    @owner = current_user.id == @project.user_id
    @milestones = (@owner ? @project.milestones : Milestone.where(id: @project.agreements.joins(:agreement_participants).where(agreement_participants: { user_id: current_user.id }).pluck(:milestone_ids).flatten))
    @milestones_pending_confirmation = @milestones
                                         .includes(:time_logs)
                                         .where(status: "in_progress", time_logs: { status: "completed" })
  end
end
