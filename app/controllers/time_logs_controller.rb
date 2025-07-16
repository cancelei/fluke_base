class TimeLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, except: [ :filter ]
  before_action :set_milestone, only: [ :create, :stop_tracking ]
  before_action :set_time_log, only: [ :stop_tracking ]
  before_action :set_manual_time_log, only: [ :index ]
  before_action :ensure_no_active_time_log, only: [ :create_manual, :create ]

  def create_manual
    @time_log = @project.time_logs.new(time_log_params)
    @time_log.user = current_user
    @time_log.status = "completed"

    if @time_log.save
      redirect_to time_logs_path(@project), notice: "Time log created successfully."
    else
      redirect_to time_logs_path(@project), alert: @time_log.errors.full_messages.to_sentence
    end
  end

  def index
    @owner = current_user.id == @project.user_id
    # Set the selected date or default to today
    @selected_date = params[:date].present? ? Date.parse(params[:date]) : Date.current

    # Get the date range for the carousel (3 days before and after selected date)
    @date_range = (@selected_date - 3.days)..(@selected_date + 3.days)

    # Get milestones for the current project's project
    @milestones = (@owner ? @project.milestones : Milestone.where(id: @project.agreements.where("initiator_id = ? OR other_party_id = ?", current_user.id, current_user.id).pluck(:milestone_ids).flatten))

    # Get time logs for the selected date
    @time_logs = @project.time_logs
                           .includes(:milestone)
                           .order(started_at: :desc)

    @milestones_pending_confirmation = @milestones
                                         .includes(:time_logs)
                                         .where(status: "in_progress", time_logs: { status: "completed" })
    @time_logs_completed = @milestones
                            .includes(:time_logs)
                            .where(status: Milestone::COMPLETED, time_logs: { status: "completed" })
  end

  def create
    @time_log = @project.time_logs.new(
      milestone: @milestone,
      started_at: Time.current,
      status: "in_progress",
      user: current_user
    )

    if @time_log.save
      session[:progress_milestone_id] = @time_log.milestone_id
      Milestone.find_by_id(@time_log.milestone_id).update(status: "in_progress")
      redirect_to time_logs_path(@project), notice: "Started tracking time for this milestone."
    else
      redirect_to time_logs_path(@project), alert: @time_log.errors.full_messages.to_sentence
    end
  end

  def stop_tracking
    if @time_log.complete!
      session[:progress_milestone_id] = nil
      redirect_to time_logs_path(@project), notice: "Stopped tracking time."
    else
      redirect_to time_logs_path(@project), alert: @time_log.errors.full_messages.to_sentence
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
  end

  private

  def time_log_params
    params.require(:time_log).permit(:started_at, :ended_at, :description, :milestone_id, :manual_entry)
  end

  def ensure_no_active_time_log
    if time_log_in_progress
      redirect_to time_logs_path(@project), alert: "You already have a time log in progress."
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
    redirect_to time_logs_path(@project), alert: "Milestone not found."
  end

  def set_time_log
    @time_log = @project.time_logs.in_progress.find_by(milestone: @milestone)
    return if @time_log.present?

    redirect_to time_logs_path(@project), alert: "No active time log found for this milestone."
  end

  def time_log_in_progress
    @project.time_logs.in_progress.where(user_id: current_user.id).exists?
  end
end
