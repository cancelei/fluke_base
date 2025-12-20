class AgreementsController < ApplicationController
  include ActionView::RecordIdentifier
  include ResultHandling
  include ProjectContextSwitchable

  before_action :authenticate_user!
  before_action :set_agreement, only: %i[show edit update destroy accept reject complete cancel counter_offer meetings_section github_section time_logs_section counter_offers_section]
  before_action :authorize_agreement, only: %i[show meetings_section github_section time_logs_section counter_offers_section]
  before_action :check_project_ownership, only: %i[new create]
  before_action :ensure_can_modify, only: %i[edit update destroy]
  before_action :authorize_agreement_action, only: %i[accept reject counter_offer cancel]

  def index
    @query = AgreementsQuery.new(current_user, filter_params)
    @my_agreements = @query.my_agreements
    @other_party_agreements = @query.other_party_agreements

    respond_to do |format|
      format.html do
        if turbo_frame_request?
          turbo_frame = request.headers["Turbo-Frame"]
          case turbo_frame
          when "agreement_results"
            # For filter requests, return the entire results area
            render partial: "agreement_results", layout: false
          when "agreements_my"
            # For pagination requests on my agreements table
            render partial: "my_agreements_section", layout: false, locals: { my_agreements: @my_agreements, query: @query }
          when "agreements_other"
            # For pagination requests on other party agreements table
            render partial: "other_agreements_section", layout: false, locals: { other_party_agreements: @other_party_agreements, query: @query }
          else
            render partial: "agreement_results", layout: false
          end
        else
          render :index
        end
      end
      format.turbo_stream do
        # Handle filter form submissions with Turbo Stream
        render turbo_stream: [
          turbo_stream.update("agreement_filters", partial: "filters"),
          turbo_stream.update("agreement_results", partial: "agreement_results")
        ]
      end
    end
  end

  def show
    @project = @agreement.project

    # Auto-select the agreement's project in the context navigation
    # This ensures the project dropdown matches the agreement being viewed
    switch_project_context(@project) if @project

    # Heavy data loading moved to lazy sections:
    # - @meetings moved to meetings_section
    # - GitHub logs moved to github_section
    # - Time logs moved to time_logs_section
    # - Counter offers moved to counter_offers_section

    # Check if the current user has permission to view full project details
    @can_view_full_details = @agreement.can_view_full_project_details?(current_user)

    # Calculate financial details for all payment types (lightweight calculations only)
    if @agreement.active? || @agreement.completed?
      @total_cost = @agreement.calculate_total_cost
      @duration_weeks = @agreement.duration_in_weeks
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        agreement_stream = turbo_stream.replace(
          dom_id(@agreement),
          partial: "agreement_show_content",
          locals: { agreement: @agreement, project: @project, can_view_full_details: @can_view_full_details }
        )
        # Include project context streams to update the navbar when context changes
        render turbo_stream: project_context_turbo_streams_with(agreement_stream)
      end
    end
  end

  def new
    # Allow counter offers, but prevent duplicate agreements
    if duplicate_agreement_exists?
      flash[:alert] = duplicate_agreement_flash
      redirect_to agreements_path
      return
    end

    set_project_from_params_or_session

    if params[:counter_to_id].present?
      # Handle counter offer case
      original_agreement = Agreement.find(params[:counter_to_id])
      @project = original_agreement.project
      # Initiator details will be handled through agreement_participants

      # Pre-populate form with original agreement data for counter offer
      @agreement_form = AgreementForm.new(
        project_id: original_agreement.project_id,
        initiator_user_id: current_user.id,
        other_party_user_id: params[:other_party_id],
        agreement_type: original_agreement.agreement_type,
        payment_type: original_agreement.payment_type,
        start_date: original_agreement.start_date,
        end_date: original_agreement.end_date,
        tasks: original_agreement.tasks,
        weekly_hours: original_agreement.weekly_hours,
        hourly_rate: original_agreement.hourly_rate,
        equity_percentage: original_agreement.equity_percentage,
        milestone_ids: original_agreement.milestone_ids,
        counter_agreement_id: params[:counter_to_id]
      )
    else
      # Handle new agreement case
      form_params = {
        project_id: params[:project_id] || @project&.id,
        other_party_user_id: params[:other_party_id]
      }
      @agreement_form = AgreementForm.new(form_params)
    end

    @other_party = User.find_by_id(params[:other_party_id])
    @milestone_ids = @agreement_form.milestone_ids_array
  rescue Pundit::NotAuthorizedError
    redirect_to agreements_path, alert: "You are not authorized to view this agreement."
  end

  def edit
    authorize @agreement
    @project = @agreement.project

    # Get participants using AgreementParticipants
    initiator = @agreement.agreement_participants.find_by(is_initiator: true)&.user
    other_party = @agreement.agreement_participants.find_by(is_initiator: false)&.user

    # Initialize form object with current agreement data
    @agreement_form = AgreementForm.new(
      project_id: @agreement.project_id,
      initiator_user_id: initiator&.id,
      other_party_user_id: other_party&.id,
      agreement_type: @agreement.agreement_type,
      payment_type: @agreement.payment_type,
      start_date: @agreement.start_date,
      end_date: @agreement.end_date,
      tasks: @agreement.tasks,
      weekly_hours: @agreement.weekly_hours,
      hourly_rate: @agreement.hourly_rate,
      equity_percentage: @agreement.equity_percentage,
      milestone_ids: @agreement.milestone_ids,
      counter_agreement_id: @agreement.agreement_participants.first&.counter_agreement_id,
      status: @agreement.status
    )

    @milestone_ids = @agreement_form.milestone_ids_array
  end

  def create
    form_params = agreement_params.merge(
      initiator_user_id: current_user.id,
      other_party_user_id: params.dig(:agreement, :other_party_user_id),
      milestone_ids: params[:agreement][:milestone_ids]
    )

    @agreement_form = AgreementForm.new(form_params)

    if @agreement_form.save
      @agreement = @agreement_form.agreement

      # Determine success message based on whether it's a counter offer
      if @agreement_form.is_counter_offer?
        notice_message = "Counter offer was successfully created and sent to #{@agreement.other_party&.full_name || 'the other party'}. They'll be notified to review your proposal."
        notify_and_message_other_party(:counter_offer)
      else
        notice_message = "Agreement proposal sent to #{@agreement.other_party&.full_name || 'the other party'}! They'll be notified to review and respond."
        notify_and_message_other_party(:create)
      end

      # Redirect to the agreement show page for better context
      redirect_to @agreement, notice: notice_message
    else
      @agreement_form.errors.full_messages.each { |error| flash[:alert] = error }
      @project = @agreement_form.project
      @agreement = Agreement.new  # For authorization checks in the form
      @milestone_ids = @agreement_form.milestone_ids_array
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @agreement

    # Use AgreementForm to handle the update properly
    form_params = agreement_params.merge(
      project_id: @agreement.project_id,
      initiator_user_id: @agreement.agreement_participants.find_by(is_initiator: true)&.user_id,
      other_party_user_id: @agreement.agreement_participants.find_by(is_initiator: false)&.user_id,
      milestone_ids: params[:agreement][:milestone_ids]
    )

    @agreement_form = AgreementForm.new(form_params)

    if @agreement_form.update_agreement(@agreement)
      notify_and_message_other_party(:update)
      redirect_to @agreement, notice: "Agreement was successfully updated."
    else
      # Ensure @project is set for the form partial
      @project = @agreement.project

      # Get participants for form display
      initiator = @agreement.agreement_participants.find_by(is_initiator: true)&.user
      other_party = @agreement.agreement_participants.find_by(is_initiator: false)&.user
      @other_party = other_party

      # Create form object for display with current agreement data
      @agreement_form = AgreementForm.new(
        project_id: @agreement.project_id,
        initiator_user_id: initiator&.id,
        other_party_user_id: other_party&.id,
        agreement_type: @agreement.agreement_type,
        payment_type: @agreement.payment_type,
        start_date: @agreement.start_date,
        end_date: @agreement.end_date,
        tasks: @agreement.tasks,
        weekly_hours: @agreement.weekly_hours,
        hourly_rate: @agreement.hourly_rate,
        equity_percentage: @agreement.equity_percentage,
        milestone_ids: @agreement.milestone_ids,
        counter_agreement_id: @agreement.agreement_participants.first&.counter_agreement_id,
        status: @agreement.status
      )

      @milestone_ids = @agreement_form.milestone_ids_array

      render :edit, status: :unprocessable_content
    end
  rescue Pundit::NotAuthorizedError
    redirect_to agreements_path, alert: "You are not authorized to view this agreement."
  end

  def destroy
    authorize @agreement
    @agreement.destroy
    redirect_to agreements_url, notice: "Agreement was successfully destroyed."
  rescue Pundit::NotAuthorizedError
    redirect_to agreements_path, alert: "You are not authorized to view this agreement."
  end

  # State transition actions - authorization handled by before_action or inline
  # See before_action :authorize_agreement_action for accept, reject, cancel
  def accept
    transition_agreement_state(:accept, "Agreement was successfully accepted.")
  end

  def reject
    transition_agreement_state(:reject, "Agreement was successfully rejected.")
  end

  def complete
    authorize @agreement, :complete?
    transition_agreement_state(:complete, "This agreement has been marked as completed.")
  rescue Pundit::NotAuthorizedError
    message = "Agreement cannot be marked as completed"
    respond_to do |format|
      format.turbo_stream { render_turbo_flash_error(message) }
      format.html { redirect_to @agreement, alert: message }
    end
  end

  def cancel
    transition_agreement_state(:cancel, "Agreement was successfully cancelled.")
  end

  def counter_offer
    # Get the initiator using AgreementParticipants
    initiator = @agreement.agreement_participants.find_by(is_initiator: true)&.user

    # Create a new agreement form based on the current one
    redirect_to new_agreement_path(
      project_id: @agreement.project_id,
      counter_to_id: @agreement.id,
      other_party_id: initiator&.id
    )
  end

  # Lazy loading sections
  def meetings_section
    render_lazy_section("meetings", "Meetings", "Scheduled meetings and collaboration sessions") do
      @project = @agreement.project
      @meetings = (@agreement.active? || @agreement.completed?) ? @agreement.meetings.includes(:agreement).order(start_time: :asc) : []
      { agreement: @agreement, meetings: @meetings, project: @project }
    end
  end

  def github_section
    render_lazy_section("github", "GitHub Integration", "Repository access and development activity") do
      @can_view_full_details = @agreement.can_view_full_project_details?(current_user)
      @project = Project.includes(:github_logs).find(@agreement.project.id)
      { agreement: @agreement, project: @project, can_view_full_details: @can_view_full_details }
    end
  end

  def time_logs_section
    render_lazy_section("time_logs", "Time Tracking", "Hours spent and remaining time for this agreement") do
      @project = @agreement.project
      @can_view_full_details = @agreement.can_view_full_project_details?(current_user)
      @project = Project.includes(time_logs: :user).find(@project.id) if @can_view_full_details
      agreement_participant_ids = @agreement.agreement_participants.pluck(:user_id)
      @agreement_participant_time_logs = @project.time_logs.where(user_id: agreement_participant_ids)
      { agreement: @agreement, project: @project, can_view_full_details: @can_view_full_details, agreement_participant_time_logs: @agreement_participant_time_logs }
    end
  end

  def counter_offers_section
    render_lazy_section("counter_offers", "Negotiation History", "Changes and counter-offers made during negotiation") do
      @agreement_chain = build_agreement_chain_optimized(@agreement)
      { agreement: @agreement, agreement_chain: @agreement_chain }
    end
  end

  private

    # Unified lazy section renderer with error handling
    #
    # IMPORTANT: Lazy-loaded turbo frames (turbo_frame_tag with src: and loading: "lazy")
    # expect an HTML response containing a matching <turbo-frame id="..."> element.
    # They do NOT work with turbo_stream responses (which use <turbo-stream action="replace">).
    #
    # The partial being rendered MUST include a turbo_frame_tag wrapper with the matching ID.
    # See: https://turbo.hotwired.dev/reference/frames (Lazy-loaded frame documentation)
    def render_lazy_section(section_name, error_title, error_description)
      locals = yield
      partial_name = "#{section_name}_section"

      # Render the partial directly - the partial must include its own turbo_frame_tag wrapper
      # with the correct frame_id: "#{dom_id(@agreement)}_#{section_name}"
      render partial: partial_name, locals:, layout: false, formats: [:html]
    rescue => e
      Rails.logger.error "Error loading #{section_name} section: #{e.message}"
      frame_id = "#{dom_id(@agreement)}_#{section_name}"
      # For errors, we need to wrap the error partial in a turbo_frame_tag
      # because the error partial doesn't have its own frame wrapper
      html = view_context.turbo_frame_tag(frame_id) do
        view_context.render(partial: "lazy_loading_error", locals: { title: error_title, description: error_description }, formats: [:html])
      end
      render html:, layout: false
    end

    # --- Refactored helpers below ---

    def filter_by_status!(my_agreements, other_party_agreements)
      return unless params[:status].present?
      my_agreements.where!(status: params[:status])
      other_party_agreements.where!(status: params[:status])
    end

    def duplicate_agreement_exists?
      return false if params[:counter_to_id].present? # Counter offers are allowed
      return false unless params[:other_party_id].present? && params[:project_id].present?

      # Check for existing agreements using the new AgreementParticipants structure
      query = Agreement.joins(:agreement_participants)
        .where(project_id: params[:project_id], status: [Agreement::ACCEPTED, Agreement::PENDING])
        .where(agreement_participants: { user_id: [current_user.id, params[:other_party_id]] })
        .group("agreements.id")
        .having("COUNT(agreement_participants.id) = 2")

      # Exclude current agreement if editing
      if params[:id].present?
        query = query.where.not(id: params[:id])
      end

      query.exists?
    end

    def duplicate_agreement_flash
      # Find existing agreement using AgreementParticipants structure
      agreement = Agreement.joins(:agreement_participants)
        .where(project_id: params[:project_id], status: [Agreement::ACCEPTED, Agreement::PENDING])
        .where(agreement_participants: { user_id: [current_user.id, params[:other_party_id]] })
        .group("agreements.id")
        .having("COUNT(agreement_participants.id) = 2")
        .first

      "You currently have an agreement with this mentor for this project. View agreement <b><a href='#{agreement_path(agreement.id)}'>here</a></b>".html_safe
    end

    def set_project_from_params_or_session
      if params[:project_id].present?
        @project = Project.find(params[:project_id])
        session[:selected_project_id] = @project.id if @project
      elsif current_user.selected_project.present?
        @project = current_user.selected_project
      end
    end

    def handle_edit_counter_offer
      if @agreement.countered?
        @latest_counter_offer = @agreement.latest_counter_offer
        if @latest_counter_offer
          @agreement = @latest_counter_offer
        else
          redirect_to @agreement, alert: "This agreement has been countered but no counter offer exists yet. Please create a new counter offer instead."
          nil
        end
      end
    end

    def set_project_and_mentor_for_edit
      @project = @agreement.project
      @milestones = Milestone.where(project_id: @project.id)
      session[:selected_project_id] = @project.id
    end

    def handle_counter_offer_for_edit
      if params[:counter_to_id].present?
        @agreement.countered_to(params[:counter_to_id])
        @original_agreement = Agreement.find(params[:counter_to_id])
        if @agreement.errors.any?
          redirect_to agreement_path(params[:counter_to_id]), alert: "You can only make counter offers to pending agreements."
          return
        end
        @original_agreement = @agreement.counter_to
        @is_counter_offer = true
      else
        @is_counter_offer = false
      end
    end

    # Centralized notification and message logic
    def notify_and_message_other_party(action)
      other_party = if @original_agreement&.present? && [:create].include?(action)
        current_user.id == @original_agreement.initiator&.id ? @original_agreement.other_party : @original_agreement.initiator
      else
        current_user.id == @agreement.initiator&.id ? @agreement.other_party : @agreement.initiator
      end
      case action
      when :create
        if @original_agreement&.present?
          notify_and_message(
            other_party,
            "New Counter Offer",
            "#{current_user.full_name} has made a counter offer for project #{@agreement.project.name}",
            "[Automated] #{current_user.full_name} has made a counter offer for project '#{@agreement.project.name}'. Please review the new terms. #{details_link}"
          )
        else
          notify_and_message(
            other_party,
            "New Agreement Proposal",
            "#{current_user.full_name} has proposed an agreement for project #{@agreement.project.name}",
            "[Automated] #{current_user.full_name} has proposed an agreement for project '#{@agreement.project.name}'. Please review the new terms. #{details_link}"
          )
        end
      when :update
        notify_and_message(
          other_party,
          "New Agreement Proposal",
          "#{current_user.full_name} has changed the terms for an agreement for project #{@agreement.project.name}",
          "[Automated] #{current_user.full_name} has changed the terms for an agreement for project '#{@agreement.project.name}'. Please review the new terms. #{details_link}"
        )
      when :accept
        notify_and_message(
          other_party,
          "New Agreement Proposal",
          "#{current_user.full_name} has accepted an agreement for project #{@agreement.project.name}",
          "[Automated] #{current_user.full_name} has accepted an agreement for project '#{@agreement.project.name}'. Please review the new terms. #{details_link}"
        )
      when :reject
        notify_and_message(
          other_party,
          "New Agreement Proposal",
          "#{current_user.full_name} has rejected an agreement for project #{@agreement.project.name}",
          "[Automated] #{current_user.full_name} has rejected an agreement for project '#{@agreement.project.name}'. Please review the new terms. #{details_link}"
        )
      when :complete
        notify_and_message(
          other_party,
          "New Agreement Proposal",
          "#{current_user.full_name} has marked the agreement for project #{@agreement.project.name} as completed",
          "[Automated] #{current_user.full_name} has marked the agreement for project '#{@agreement.project.name}' as completed. Please review the new terms. #{details_link}"
        )
      when :cancel
        notify_and_message(
          other_party,
          "New Agreement Proposal",
          "#{current_user.full_name} has canceled an agreement for project #{@agreement.project.name}",
          "[Automated] #{current_user.full_name} has canceled an agreement for project '#{@agreement.project.name}'. Please review the new terms. #{details_link}"
        )
      end
    end

    def notify_and_message(other_party, title, message, body)
      NotificationService.new(other_party).notify(
        title:,
        message:,
        url: agreement_path(@agreement)
      )
      conversation = Conversation.between(current_user.id, other_party.id)
      Message.create!(
        conversation:,
        user: current_user,
        body:
      )
    end

    def set_agreement
      @agreement = Agreement.includes(
        project: :user,
        agreement_participants: :user,
        meetings: []
      ).find(params[:id])
    end

    def authorize_agreement
      authorize @agreement
    rescue Pundit::NotAuthorizedError
      redirect_to agreements_path, alert: "You are not authorized to view this agreement."
    end

    def check_project_ownership
      # Robustly skip project ownership check for counter offers (at any param nesting)
      counter_to_id = params[:counter_to_id]
      counter_to_id ||= params[:agreement][:counter_to_id] if params[:agreement] && params[:agreement][:counter_to_id].present?

      # Skip project ownership check for counter offers
      if counter_to_id.present?
        return
      end

      # Get project_id from params
      project_id = params[:project_id]
      project_id ||= params[:agreement][:project_id] if params[:agreement].present?

      # Require a project when not acting as a mentor
      if project_id.blank?
        redirect_to projects_path, alert: "No project selected. Please select a project before creating an agreement."
        return
      end

      @project = Project.find(project_id)

      if !(params[:other_party_id] || params.dig(:agreement, :other_party_user_id))
        redirect_to projects_path, alert: "Select the other user to create agreement"
      end
    end

    def ensure_can_modify
      # Only allow modification of pending agreements by the entrepreneur
      # or the mentor if they initiated the agreement
      unless policy(@agreement).show?
        redirect_to agreements_path, alert: "You are not authorized to view this agreement."
        return
      end

      if @agreement.countered?
        redirect_to @agreement, alert: "This agreement has been countered. Please create a new counter offer instead of editing."
        return
      end

      unless (@agreement.pending? && current_user.id == @agreement.initiator&.id) ||
             (@agreement.pending? && current_user.id == @agreement.other_party&.id && !@agreement.is_counter_offer?)
        redirect_to @agreement, alert: "You cannot modify this agreement."
      end
    end

    def agreement_params
      permitted_params = params.require(:agreement).permit(
        :project_id, :initiator_user_id, :other_party_user_id,
        :agreement_type, :payment_type, :start_date, :end_date,
        :tasks, :weekly_hours, :hourly_rate, :equity_percentage,
        :counter_agreement_id, :status, :terms, milestone_ids: []
      )

      # Sanitize HTML content for security
      permitted_params[:tasks] = ActionController::Base.helpers.sanitize(permitted_params[:tasks]) if permitted_params[:tasks]
      permitted_params[:terms] = ActionController::Base.helpers.sanitize(permitted_params[:terms]) if permitted_params[:terms]

      permitted_params
    end

  def authorize_agreement_action
    action = "#{params[:action]}?".to_sym
    unless policy(@agreement).public_send(action)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = "You are not authorized to perform this action."
          render turbo_stream: turbo_stream.prepend(
            "flash_messages",
            partial: "shared/flash_message",
            locals: { type: "alert", message: flash.now[:alert] }
          )
        end
        format.html do
          redirect_to @agreement, alert: "You are not authorized to perform this action."
        end
      end
      return false
    end
    true
  end

  # Consolidated state transition handler for accept, reject, complete, cancel actions
  # Reduces ~90 lines of duplicate code to a single reusable method
  # Note: Authorization is handled by before_action or called inline before this method
  def transition_agreement_state(action, success_message)
    result = @agreement.public_send("#{action}!")

    handle_result(result) do |type, value|
      case type
      when :success
        notify_and_message_other_party(action)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = success_message
            render action
          end
          format.html { redirect_to @agreement, notice: success_message }
        end
      when :failure
        alert_message = error_message(value)
        respond_to do |format|
          format.turbo_stream { render_turbo_flash_error(alert_message) }
          format.html { redirect_to @agreement, alert: alert_message }
        end
      end
    end
  end

    def details_link
      <<~HTML
        <a href="#{agreement_path(@agreement)}" class="p-1 bg-white text-gray-500">View Details</a>
      HTML
    end

    def filter_params = params.permit(:project_id, :status, :agreement_type, :start_date_from, :start_date_to, :end_date_from, :end_date_to, :search, :clear_filters, :page, :turbo_frame)

    def build_agreement_chain_optimized(agreement)
      # Collect all agreement IDs in the chain first
      chain_ids = []
      current = agreement
      chain_ids << current.id

      while current.counter_to_id.present?
        chain_ids << current.counter_to_id
        current = current.counter_to
      end

      # Load all agreements in the chain with includes to avoid N+1
      agreements_by_id = Agreement.includes(
        agreement_participants: :user
      ).where(id: chain_ids).index_by(&:id)

      # Rebuild the chain with preloaded data
      agreement_chain = []
      current = agreement
      while current.counter_to_id.present?
        previous = agreements_by_id[current.counter_to_id]
        agreement_chain << [current, previous]
        current = previous
      end

      agreement_chain
    end
end
