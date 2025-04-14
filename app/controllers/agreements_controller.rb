class AgreementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_agreement, only: [ :show, :edit, :update, :destroy, :accept, :reject, :complete, :cancel, :counter_offer ]
  before_action :authorize_agreement, only: [ :show, :edit, :update, :destroy ]
  before_action :check_project_ownership, only: [ :new, :create ]
  before_action :ensure_can_modify, only: [ :edit, :update, :destroy ]
  before_action :authorize_agreement_action, only: [ :accept, :reject, :counter_offer, :cancel ]

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
    @agreement.entrepreneur = current_user
    @agreement.status = Agreement::PENDING

    # Set the selected project if project_id is provided
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
      session[:selected_project_id] = @project.id if @project
    end

    # Set the mentor if mentor_id is provided
    if params[:mentor_id].present?
      @mentor = User.find(params[:mentor_id])
      @agreement.mentor_id = @mentor.id
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
      @agreement.entrepreneur_id = @project.user_id if @project
      @mentor_initiated = true
    end

    # Ensure mentor is loaded even if it's a counter offer
    @mentor = @agreement.mentor if @mentor.nil?
  end

  def edit
    authorize! :edit, @agreement

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
    @agreement = Agreement.new(agreement_params)
    @agreement.entrepreneur = current_user
    @agreement.status = Agreement::PENDING

    # Handle counter offers
    if params[:counter_to_id].present?
      @original_agreement = Agreement.find(params[:counter_to_id])
      @agreement.counter_to_id = @original_agreement.id
    end

    if @agreement.save
      # If this is a counter offer, update the original agreement status
      if @original_agreement.present?
        @original_agreement.update(status: Agreement::COUNTERED)
      end

      # Notify the mentor about the new agreement
      NotificationService.new(@agreement.mentor).notify(
        title: "New Agreement Proposal",
        message: "#{current_user.full_name} has proposed an agreement for project #{@agreement.project.name}",
        url: agreement_path(@agreement)
      )

      redirect_to @agreement, notice: "Agreement was successfully created."
    else
      # When re-rendering the form after validation errors, ensure @project and @mentor are set
      @project = @agreement.project
      @mentor = @agreement.mentor
      render :new
    end
  end

  def update
    authorize! :edit, @agreement

    if @agreement.update(agreement_params)
      redirect_to @agreement, notice: "Agreement was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, @agreement
    @agreement.destroy
    redirect_to agreements_url, notice: "Agreement was successfully destroyed."
  end

  def accept
    if @agreement.accept!
      redirect_to @agreement, notice: "Agreement was successfully accepted."
    else
      redirect_to @agreement, alert: "Unable to accept agreement."
    end
  end

  def reject
    if @agreement.reject!
      redirect_to @agreement, notice: "Agreement was successfully rejected."
    else
      redirect_to @agreement, alert: "Unable to reject agreement."
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
    if @agreement.cancel!
      redirect_to @agreement, notice: "Agreement was successfully cancelled."
    else
      redirect_to @agreement, alert: "Unable to cancel agreement."
    end
  end

  def counter_offer
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

    def authorize_agreement_action
      action = params[:action].to_sym
      authorize! action, @agreement
    end
end
