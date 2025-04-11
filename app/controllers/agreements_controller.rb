class AgreementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_agreement, only: [ :show, :edit, :update, :destroy, :accept, :reject, :complete, :cancel, :counter_offer ]
  before_action :authorize_agreement, only: [ :show, :edit, :update, :destroy ]
  before_action :check_project_ownership, only: [ :new, :create ]
  before_action :ensure_can_modify, only: [ :edit, :update, :destroy ]

  def index
    # Separate agreements based on user role
    @entrepreneur_agreements = current_user.entrepreneur_agreements
                                          .includes(:project, :mentor)
                                          .order(created_at: :desc)

    @mentor_agreements = current_user.mentor_agreements
                                    .includes(:project, :entrepreneur)
                                    .order(created_at: :desc)

    # Apply status filter if provided
    if params[:status].present?
      @entrepreneur_agreements = @entrepreneur_agreements.where(status: params[:status])
      @mentor_agreements = @mentor_agreements.where(status: params[:status])
    end
  end

  def show
    @project = @agreement.project
    @meetings = @agreement.meetings.order(start_time: :asc) if @agreement.active? || @agreement.completed?

    # Check if the current user has permission to view full project details
    @can_view_full_details = @agreement.can_view_full_project_details?(current_user)

    # Calculate financial details for all payment types
    if @agreement.active? || @agreement.completed?
      @total_cost = @agreement.calculate_total_cost
      @duration_weeks = @agreement.duration_in_weeks
    end
  end

  def new
    @agreement = Agreement.new
    @agreement.mentor_id = params[:mentor_id] if params[:mentor_id].present?

    # Set the selected project if project_id is provided
    if params[:project_id].present?
      @project = current_user.projects.find_by(id: params[:project_id])
      session[:selected_project_id] = @project.id if @project
    end

    # Set the mentor if mentor_id is provided
    if params[:mentor_id].present?
      @mentor = User.find(params[:mentor_id])
    end

    # Handle counter offers
    if params[:counter_to_id].present?
      @original_agreement = Agreement.find(params[:counter_to_id])

      # Only allow counter offers for pending agreements
      unless @original_agreement.pending?
        redirect_to agreement_path(@original_agreement), alert: "You can only make counter offers to pending agreements."
        return
      end

      # Pre-fill data from the original agreement
      @agreement.project_id = @original_agreement.project_id
      @agreement.mentor_id = @original_agreement.mentor_id
      @agreement.entrepreneur_id = @original_agreement.entrepreneur_id
      @agreement.agreement_type = @original_agreement.agreement_type
      @agreement.payment_type = @original_agreement.payment_type
      @agreement.start_date = @original_agreement.start_date
      @agreement.end_date = @original_agreement.end_date
      @agreement.weekly_hours = @original_agreement.weekly_hours
      @agreement.hourly_rate = @original_agreement.hourly_rate
      @agreement.equity_percentage = @original_agreement.equity_percentage
      @agreement.tasks = @original_agreement.tasks
      @agreement.terms = @original_agreement.terms

      @is_counter_offer = true
    else
      @is_counter_offer = false
    end

    # Handle mentor initiated agreements
    if params[:mentor_initiated] && current_user.has_role?(:mentor)
      @agreement.mentor_id = current_user.id
      @agreement.entrepreneur_id = @project.user_id
      @mentor_initiated = true
    else
      @agreement.entrepreneur_id = current_user.id
      @mentor_initiated = false

      # Only check for potential mentors if no specific mentor is selected
      unless @agreement.mentor_id.present?
        # Get potential mentors (users with mentor role that are not already in an agreement for this project)
        @potential_mentors = User.with_role(:mentor)
                                .where.not(id: @project.agreements.pluck(:mentor_id))

        if @potential_mentors.empty? && !@is_counter_offer
          # If no mentors are available, redirect with a flash message
          redirect_to projects_path, alert: "No mentors are currently available for this project. Please try again later or invite someone to join as a mentor."
          nil
        end
      end
    end
  end

  def edit
    # Set the project and mentor for the view
    @project = @agreement.project
    @mentor = @agreement.mentor
    session[:selected_project_id] = @project.id

    # Handle counter offers
    if params[:counter_to_id].present?
      @original_agreement = Agreement.find(params[:counter_to_id])

      # Only allow counter offers for pending agreements
      unless @original_agreement.pending?
        redirect_to agreement_path(@original_agreement), alert: "You can only make counter offers to pending agreements."
        return
      end

      # Pre-fill data from the original agreement
      @agreement.project_id = @original_agreement.project_id
      @agreement.mentor_id = @original_agreement.mentor_id
      @agreement.entrepreneur_id = @original_agreement.entrepreneur_id
      @agreement.agreement_type = @original_agreement.agreement_type
      @agreement.payment_type = @original_agreement.payment_type
      @agreement.start_date = @original_agreement.start_date
      @agreement.end_date = @original_agreement.end_date
      @agreement.weekly_hours = @original_agreement.weekly_hours
      @agreement.hourly_rate = @original_agreement.hourly_rate
      @agreement.equity_percentage = @original_agreement.equity_percentage
      @agreement.tasks = @original_agreement.tasks
      @agreement.terms = @original_agreement.terms

      @is_counter_offer = true
    else
      @is_counter_offer = false
    end

    # Ensure mentor is loaded even if it's a counter offer
    @mentor = @agreement.mentor if @mentor.nil?
  end

  def create
    begin
      @project = Project.find(params[:agreement][:project_id])
      @agreement = Agreement.new(agreement_params)

      # Handle mentor initiated agreements
      if params[:mentor_initiated] && current_user.has_role?(:mentor)
        @agreement.mentor = current_user
        @agreement.entrepreneur_id = @project.user_id
        notify_party = @agreement.entrepreneur
        notification_message = "#{current_user.full_name} has proposed an agreement to collaborate on your project #{@project.name}"
        @mentor_initiated = true
      else
        @agreement.entrepreneur = current_user
        notify_party = @agreement.mentor
        notification_message = "#{current_user.full_name} has proposed an agreement for you on project #{@project.name}"
        @mentor_initiated = false

        # Get potential mentors
        @potential_mentors = User.with_role(:mentor)
                                .where.not(id: @project.agreements.pluck(:mentor_id))
      end

      # Handle counter offers
      if params[:counter_to_id].present?
        @original_agreement = Agreement.find(params[:counter_to_id])
        is_counter_offer = true
      else
        is_counter_offer = false
      end

      # Modify notification if it's a counter offer
      if is_counter_offer
        notification_message = "#{current_user.full_name} has made a counter offer for project #{@project.name}"
      end

      @agreement.status = Agreement::PENDING

      # Set default values based on payment type if needed
      case @agreement.payment_type
      when Agreement::EQUITY
        @agreement.hourly_rate = 0 unless @agreement.hourly_rate.present?
      when Agreement::HOURLY
        @agreement.equity_percentage = 0 unless @agreement.equity_percentage.present?
      end

      respond_to do |format|
        if @agreement.save
          # If this is a counter offer, update the original agreement status
          if is_counter_offer
            @original_agreement.counter_offer!(@agreement)
          end

          # Notify the other party about the new agreement
          NotificationService.new(notify_party).notify(
            title: is_counter_offer ? "Counter Offer Received" : "New Agreement Proposal",
            message: notification_message,
            url: agreement_path(@agreement)
          )

          format.html { redirect_to agreements_path, notice: "#{is_counter_offer ? 'Counter offer' : 'Agreement proposal'} was successfully created and sent to #{notify_party.full_name}." }
          format.json { render :show, status: :created, location: @agreement }
        else
          # When re-rendering the form after validation errors, ensure @potential_mentors is set
          if !@mentor_initiated && @potential_mentors.nil?
            @potential_mentors = User.with_role(:mentor)
                                    .where.not(id: @project.agreements.pluck(:mentor_id))
          end
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @agreement.errors, status: :unprocessable_entity }
        end
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:alert] = "Project not found. Please select a valid project."
        format.html { redirect_to projects_path }
        format.json { render json: { error: "Project not found" }, status: :not_found }
      end
    end
  end

  def update
    # Store the old payment type to check if it changed
    old_payment_type = @agreement.payment_type

    # Set the project and mentor for the view
    @project = @agreement.project
    @mentor = @agreement.mentor
    session[:selected_project_id] = @project.id

    respond_to do |format|
      # Set default values based on payment type if needed
      agreement_attributes = agreement_params
      if agreement_attributes[:payment_type] == Agreement::EQUITY && !agreement_attributes[:hourly_rate].present?
        agreement_attributes[:hourly_rate] = 0
      elsif agreement_attributes[:payment_type] == Agreement::HOURLY && !agreement_attributes[:equity_percentage].present?
        agreement_attributes[:equity_percentage] = 0
      end

      if @agreement.update(agreement_attributes)
        # Notify the other party about the update
        notify_party = current_user == @agreement.entrepreneur ? @agreement.mentor : @agreement.entrepreneur

        notification_title = "Agreement Updated"
        notification_message = "#{current_user.full_name} has updated the agreement for project #{@agreement.project.name}"

        # Add specific details if payment type was changed
        if old_payment_type != @agreement.payment_type
          notification_message += ". Payment type changed from #{old_payment_type} to #{@agreement.payment_type}."
        end

        NotificationService.new(notify_party).notify(
          title: notification_title,
          message: notification_message,
          url: agreement_path(@agreement)
        )

        format.html { redirect_to @agreement, notice: "Agreement was successfully updated." }
        format.json { render :show, status: :ok, location: @agreement }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @agreement.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @agreement.destroy

    # Notify the other party about the cancellation
    notify_party = current_user == @agreement.entrepreneur ? @agreement.mentor : @agreement.entrepreneur
    NotificationService.new(notify_party).notify(
      title: "Agreement Cancelled",
      message: "#{current_user.full_name} has cancelled the agreement for project #{@agreement.project.name}",
      url: projects_path
    )

    respond_to do |format|
      format.html { redirect_to agreements_url, notice: "Agreement was successfully cancelled." }
      format.json { head :no_content }
    end
  end

  def accept
    authorize! :accept, @agreement

    if @agreement.accept!
      # Notify the entrepreneur
      NotificationService.new(@agreement.entrepreneur).notify(
        title: "Agreement Accepted",
        message: "#{current_user.full_name} has accepted your agreement proposal for project #{@agreement.project.name}",
        url: agreement_path(@agreement)
      )

      redirect_to @agreement, notice: "You have accepted this agreement. You now have access to the project details."
    else
      redirect_to @agreement, alert: "This agreement cannot be accepted."
    end
  end

  def reject
    authorize! :reject, @agreement

    if @agreement.reject!
      # Notify the entrepreneur
      NotificationService.new(@agreement.entrepreneur).notify(
        title: "Agreement Rejected",
        message: "#{current_user.full_name} has declined your agreement proposal for project #{@agreement.project.name}",
        url: agreement_path(@agreement)
      )

      redirect_to @agreement, notice: "You have declined this agreement."
    else
      redirect_to @agreement, alert: "This agreement cannot be rejected."
    end
  end

  def complete
    authorize! :complete, @agreement

    if @agreement.complete!
      # Notify the other party
      notify_party = current_user == @agreement.entrepreneur ? @agreement.mentor : @agreement.entrepreneur
      NotificationService.new(notify_party).notify(
        title: "Agreement Completed",
        message: "#{current_user.full_name} has marked the agreement for project #{@agreement.project.name} as completed",
        url: agreement_path(@agreement)
      )

      redirect_to @agreement, notice: "This agreement has been marked as completed."
    else
      redirect_to @agreement, alert: "This agreement cannot be marked as completed."
    end
  end

  def cancel
    authorize! :cancel, @agreement

    if @agreement.cancel!
      # Notify the other party
      notify_party = current_user == @agreement.entrepreneur ? @agreement.mentor : @agreement.entrepreneur
      NotificationService.new(notify_party).notify(
        title: "Agreement Cancelled",
        message: "#{current_user.full_name} has cancelled the agreement for project #{@agreement.project.name}",
        url: agreement_path(@agreement)
      )

      redirect_to @agreement, notice: "This agreement has been cancelled."
    else
      redirect_to @agreement, alert: "This agreement cannot be cancelled."
    end
  end

  def counter_offer
    authorize! :counter_offer, @agreement

    # Create a new agreement form based on the current one
    redirect_to new_agreement_path(
      project_id: @agreement.project_id,
      counter_to_id: @agreement.id
    )
  end

  private
    def set_agreement
      @agreement = Agreement.find(params[:id])
    end

    def authorize_agreement
      # If the user is not part of this agreement and not an admin
      unless current_user.id == @agreement.entrepreneur_id ||
             current_user.id == @agreement.mentor_id ||
             current_user.has_role?(:admin)
        redirect_to agreements_path, alert: "You are not authorized to view this agreement."
      end
    end

    def check_project_ownership
      project_id = params[:project_id]
      project_id ||= params[:agreement][:project_id] if params[:agreement].present?

      unless project_id.present?
        redirect_to projects_path, alert: "No project selected. Please select a project before creating an agreement."
        return
      end

      @project = Project.find(project_id)

      # Allow mentors to create agreements if they're initiating it
      if params[:mentor_initiated] && current_user.has_role?(:mentor)
        # Mentors can create agreements for any project they don't already have an agreement for
        if @project.agreements.where(mentor_id: current_user.id).exists?
          redirect_to project_path(@project), alert: "You already have an agreement for this project."
          return
        end
        return # Allow mentor to proceed
      end

      # For entrepreneur-initiated agreements, check ownership
      unless current_user.id == @project.user_id
        redirect_to projects_path, alert: "You can only create agreements for your own projects."
      end
    end

    def ensure_can_modify
      # Only allow modification of pending agreements by the entrepreneur
      # or the mentor if they initiated the agreement
      unless (@agreement.pending? && current_user.id == @agreement.entrepreneur_id) ||
             (@agreement.pending? && current_user.id == @agreement.mentor_id && @agreement.is_counter_offer?)
        redirect_to @agreement, alert: "You cannot modify this agreement."
      end
    end

    def agreement_params
      params.require(:agreement).permit(
        :project_id,
        :mentor_id,
        :agreement_type,
        :start_date,
        :end_date,
        :payment_type,
        :hourly_rate,
        :equity_percentage,
        :weekly_hours,
        :tasks,
        :terms
      )
    end
end
