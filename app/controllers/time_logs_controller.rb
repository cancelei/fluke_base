class TimeLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_agreement
  before_action :set_milestone, only: [ :create, :stop_tracking ]
  before_action :set_time_log, only: [ :stop_tracking ]

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
                         .where("DATE(started_at) = ?", @selected_date)
                         .order(started_at: :desc)
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
