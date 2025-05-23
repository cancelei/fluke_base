class MeetingsController < ApplicationController
  before_action :set_agreement
  before_action :set_meeting, only: [ :show, :edit, :update, :destroy ]

  def index
    @meetings = @agreement.meetings.order(start_time: :asc)
  end

  def show
  end

  def new
    @meeting = @agreement.meetings.new
  end

  def create
    @meeting = @agreement.meetings.new(meeting_params)

    if @meeting.save
      # In a production app, this is where we'd create a Google Calendar event
      # google_calendar_event = create_google_calendar_event(@meeting)
      # @meeting.update(google_calendar_event_id: google_calendar_event.id) if google_calendar_event

      redirect_to agreement_path(@agreement), notice: "Meeting was successfully scheduled."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @meeting.update(meeting_params)
      # In a production app, this is where we'd update the Google Calendar event
      # update_google_calendar_event(@meeting) if @meeting.google_calendar_event_id.present?

      redirect_to agreement_path(@agreement), notice: "Meeting was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # In a production app, this is where we'd delete the Google Calendar event
    # delete_google_calendar_event(@meeting) if @meeting.google_calendar_event_id.present?

    @meeting.destroy
    redirect_to agreement_path(@agreement), notice: "Meeting was successfully cancelled."
  end

  private

  def set_agreement
    @agreement = current_user.all_agreements.find(params[:agreement_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to agreements_path, alert: "Agreement not found or you don't have access to it."
  end

  def set_meeting
    @meeting = @agreement.meetings.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to agreement_path(@agreement), alert: "Meeting not found."
  end

  def meeting_params
    params.require(:meeting).permit(:title, :description, :start_time, :end_time)
  end

  # Google Calendar integration methods would go here
  # def create_google_calendar_event(meeting)
  #   # Initialize Google Calendar API client
  #   # Create event in both attendees' calendars
  #   # Return the created event object
  # end

  # def update_google_calendar_event(meeting)
  #   # Update the existing Google Calendar event
  # end

  # def delete_google_calendar_event(meeting)
  #   # Delete the Google Calendar event
  # end
end
