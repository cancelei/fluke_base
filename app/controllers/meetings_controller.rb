class MeetingsController < ApplicationController
  before_action :set_agreement
  before_action :set_meeting, only: [:show, :edit, :update, :destroy]

  def index
    @meetings = @agreement.meetings.includes(:agreement).order(start_time: :asc)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render partial: "meeting_details", locals: { meeting: @meeting, agreement: @agreement }
        else
          # Full page render for direct access
        end
      end
    end
  end

  def new
    @meeting = @agreement.meetings.new

    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render partial: "form", locals: { meeting: @meeting, agreement: @agreement }
        else
          # Full page render for direct access
        end
      end
    end
  end

  def create
    @meeting = @agreement.meetings.new(meeting_params)

    respond_to do |format|
      if @meeting.save
        @meetings = @agreement.meetings.includes(:agreement).order(start_time: :asc)

        format.html { redirect_to agreement_path(@agreement), notice: "Meeting was successfully scheduled." }
        format.turbo_stream
      else
        format.html do
          if turbo_frame_request?
            render partial: "form", locals: { meeting: @meeting, agreement: @agreement }, status: :unprocessable_content
          else
            render :new, status: :unprocessable_content
          end
        end
        format.turbo_stream { render turbo_stream: turbo_stream.replace("#{dom_id(@agreement)}_meeting_form", partial: "form", locals: { meeting: @meeting, agreement: @agreement }) }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render partial: "form", locals: { meeting: @meeting, agreement: @agreement }
        else
          # Full page render for direct access
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @meeting.update(meeting_params)
        @meetings = @agreement.meetings.includes(:agreement).order(start_time: :asc)

        format.html { redirect_to agreement_path(@agreement), notice: "Meeting was successfully updated." }
        format.turbo_stream
      else
        format.html do
          if turbo_frame_request?
            render partial: "form", locals: { meeting: @meeting, agreement: @agreement }, status: :unprocessable_content
          else
            render :edit, status: :unprocessable_content
          end
        end
        format.turbo_stream { render turbo_stream: turbo_stream.replace("#{dom_id(@agreement)}_meeting_form", partial: "form", locals: { meeting: @meeting, agreement: @agreement }) }
      end
    end
  end

  def destroy
    @meeting.destroy
    @meetings = @agreement.meetings.order(start_time: :asc)

    respond_to do |format|
      format.html { redirect_to agreement_path(@agreement), notice: "Meeting was successfully cancelled." }
      format.turbo_stream
    end
  end

  private

  def set_agreement
    @agreement = current_user.all_agreements
                           .includes(
                             project: :user,
                             agreement_participants: :user,
                             meetings: []
                           )
                           .find(params[:agreement_id])
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
end
