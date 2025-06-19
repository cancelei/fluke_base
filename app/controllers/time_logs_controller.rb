class TimeLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_agreement
  before_action :set_milestone, only: [ :create, :stop_tracking ]
  before_action :set_time_log, only: [ :stop_tracking ]
  before_action :set_manual_time_log, only: [ :index ]
  before_action :ensure_no_active_time_log, only: [ :create_manual ]

  def create_manual
    if @agreement.time_logs.in_progress.exists?
      redirect_to agreement_time_logs_path(@agreement), alert: "You already have a time log in progress."
      return
    end

    @time_log = @agreement.time_logs.new(time_log_params)
    @time_log.status = "completed"

    if @time_log.save
      redirect_to agreement_time_logs_path(@agreement), notice: "Time log created successfully."
    else
      redirect_to agreement_time_logs_path(@agreement), alert: @time_log.errors.full_messages.to_sentence
    end
  end

  def index
    # Set the selected date or default to today
    @selected_date = params[:date].present? ? Date.parse(params[:date]) : Date.current

    # Get the date range for the carousel (3 days before and after selected date)
    @date_range = (@selected_date - 3.days)..(@selected_date + 3.days)

    # Get milestones for the current agreement's project
    @milestones = @agreement.project.milestones

    # Get time logs for the selected date
    @time_logs = @agreement.time_logs
                           .includes(:milestone)
                           .where("DATE(started_at) = '#{@selected_date}'")
                           .order(started_at: :desc)

    @milestones_pending_confirmation = @milestones
                                         .includes(:time_logs)
                                         .where(status: "in_progress", time_logs: { status: "completed" })
    @time_logs_completed = @milestones
                            .includes(:time_logs)
                            .where(status: "completed", time_logs: { status: "completed" })
                            .where("DATE(time_logs.started_at) = ?", @selected_date)
    @time_logs_manual = @agreement.time_logs.where(milestone_id: nil)
  end

  def create
    if @agreement.time_logs.in_progress.exists?
      redirect_to agreement_time_logs_path(@agreement), alert: "You already have a time log in progress."
      return
    end

    @time_log = @agreement.time_logs.new(
      milestone: @milestone,
      started_at: Time.current,
      status: "in_progress"
    )

    if @time_log.save
      Milestone.find_by_id(@time_log.milestone_id).update(status: "in_progress")
      redirect_to agreement_time_logs_path(@agreement), notice: "Started tracking time for this milestone."
    else
      redirect_to agreement_time_logs_path(@agreement), alert: @time_log.errors.full_messages.to_sentence
    end
  end

  def stop_tracking
    if @time_log.complete!
      redirect_to agreement_time_logs_path(@agreement), notice: "Stopped tracking time."
    else
      redirect_to agreement_time_logs_path(@agreement), alert: @time_log.errors.full_messages.to_sentence
    end
  end

  private

  def time_log_params
    params.require(:time_log).permit(:started_at, :ended_at, :description)
  end

  def ensure_no_active_time_log
    if @agreement.time_logs.in_progress.exists?
      redirect_to agreement_time_logs_path(@agreement), alert: "You already have a time log in progress."
    end
  end

  def set_manual_time_log
    @time_log_manual = TimeLog.new
  end

  def set_agreement
    # Check if user is either the mentor or entrepreneur in the agreement
    @agreement = current_user.all_agreements.find(params[:agreement_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Agreement not found or access denied."
  end

  def set_milestone
    @milestone = @agreement.project.milestones.find(params[:milestone_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to agreement_time_logs_path(@agreement), alert: "Milestone not found."
  end

  def set_time_log
    @time_log = @agreement.time_logs.in_progress.find_by(milestone: @milestone)
    return if @time_log.present?

    redirect_to agreement_time_logs_path(@agreement), alert: "No active time log found for this milestone."
  end
end
