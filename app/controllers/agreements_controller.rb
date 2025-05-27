class AgreementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_agreement, only: %i[show edit update destroy accept reject complete cancel counter_offer]
  before_action :authorize_agreement, only: %i[show edit update destroy]
  before_action :check_project_ownership, only: %i[new create]
  before_action :ensure_can_modify, only: %i[edit update destroy]
  before_action :authorize_agreement_action, only: %i[accept reject counter_offer cancel]

  def index
    @my_agreements = current_user.my_agreements
      .includes(:project, :other_party)
      .order(created_at: :desc)

    @other_party_agreements = current_user.other_party_agreements
      .includes(:project, :initiator)
      .order(created_at: :desc)

    filter_by_status!(@my_agreements, @other_party_agreements)
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
    # Allow counter offers, but prevent duplicate agreements
    if duplicate_agreement_exists?
      flash[:alert] = duplicate_agreement_flash
      redirect_to agreements_path
      return
    end
    @agreement = Agreement.new

    set_project_from_params_or_session

    if params[:counter_to_id].present?
      @agreement.countered_to(params[:counter_to_id])
    end

    @milestone_ids = @agreement.milestone_ids || []
  end

  def edit
    authorize! :edit, @agreement
    @milestone_ids = @agreement.milestone_ids || []
    handle_edit_counter_offer
    set_project_and_mentor_for_edit
    handle_counter_offer_for_edit
  end

  def create
    @agreement = Agreement.new(agreement_params)

    if @agreement.save
      notify_and_message_other_party(:create)
      # Notification and messaging can be handled by a callback or another service if needed
      redirect_to @agreement, notice: "Agreement was successfully created."
    else
      Rails.logger.debug @agreement&.errors&.full_messages&.inspect
      @agreement&.errors&.full_messages&.each { |error| flash[:alert] = error }
      @project = @agreement&.project
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize! :edit, @agreement

    if @agreement.update(params)
      notify_and_message_other_party(:update)
      redirect_to @agreement, notice: "Agreement was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @agreement
    @agreement.destroy
    redirect_to agreements_url, notice: "Agreement was successfully destroyed."
  end

  def accept
    if @agreement.accept!
      notify_and_message_other_party(:accept)
      redirect_to @agreement, notice: "Agreement was successfully accepted."
    else
      redirect_to @agreement, alert: "Unable to accept agreement."
    end
  end

  def reject
    if @agreement.reject!
      notify_and_message_other_party(:reject)
      redirect_to @agreement, notice: "Agreement was successfully rejected."
    else
      redirect_to @agreement, alert: "Unable to reject agreement."
    end
  end

  def complete
    authorize! :complete, @agreement

    if @agreement.complete!
      notify_and_message_other_party(:complete)
      redirect_to @agreement, notice: "This agreement has been marked as completed."
    else
      redirect_to @agreement, alert: "This agreement cannot be marked as completed."
    end
  end

  def cancel
    if @agreement.cancel!
      notify_and_message_other_party(:cancel)
      redirect_to @agreement, notice: "Agreement was successfully cancelled."
    else
      redirect_to @agreement, alert: "Unable to cancel agreement."
    end
  end

  def counter_offer
    # Create a new agreement form based on the current one
    redirect_to new_agreement_path(
      project_id: @agreement.project_id,
      counter_to_id: @agreement.id,
      other_party_id: @agreement.initiator_id
    )
  end

  private

    # --- Refactored helpers below ---

    def filter_by_status!(my_agreements, other_party_agreements)
      return unless params[:status].present?
      my_agreements.where!(status: params[:status])
      other_party_agreements.where!(status: params[:status])
    end

    def duplicate_agreement_exists?
      agreement = Agreement.where(other_party_id: params[:other_party_id], project_id: params[:project_id], initiator_id: current_user.id).where.not(status: Agreement::ACCEPTED).first
      params[:counter_to_id].blank? && agreement.present?
    end

    def duplicate_agreement_flash
      agreement = Agreement.where(other_party_id: params[:other_party_id], project_id: params[:project_id], initiator_id: current_user.id).where.not(status: Agreement::ACCEPTED).first
      "You currently have an agreement with this mentor for this project. View agreement <b><a href='#{agreement_path(agreement.id)}'>here</a></b>".html_safe
    end

    def set_project_from_params_or_session
      if params[:project_id].present?
        @project = Project.find(params[:project_id])
        session[:selected_project_id] = @project.id if @project
      elsif !acting_as_mentor? && current_user.selected_project.present?
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
      other_party = if @original_agreement&.present? && [ :create ].include?(action)
        current_user.id == @original_agreement.initiator_id ? @original_agreement.other_party : @original_agreement.initiator
      else
        current_user.id == @agreement.initiator_id ? @agreement.other_party : @agreement.initiator
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
        title: title,
        message: message,
        url: agreement_path(@agreement)
      )
      conversation = Conversation.between(current_user.id, other_party.id)
      Message.create!(
        conversation: conversation,
        user: current_user,
        body: body
      )
    end

    def set_agreement
      @agreement = Agreement.find(params[:id])
    end

    def authorize_agreement
      authorized = (
        current_user.id == @agreement.initiator_id ||
        current_user.id == @agreement.other_party_id ||
        current_user.has_role?(:admin)
      )

      # If not directly involved, check if user is involved in the original agreement (for counter offers)
      if !authorized && @agreement.counter_to_id.present?
        original = @agreement.counter_to
        authorized = (
          original.present? &&
          (current_user.id == original.initiator_id || current_user.id == original.other_party_id)
        )
      end

      unless authorized
        redirect_to agreements_path, alert: "You are not authorized to view this agreement."
      end
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

      if !(params[:other_party_id] || params.dig(:agreement, :other_party_id))
        redirect_to projects_path, alert: "Select the other user to create agreement"
      end
    end

    def ensure_can_modify
      # Only allow modification of pending agreements by the entrepreneur
      # or the mentor if they initiated the agreement
      if @agreement.countered?
        redirect_to @agreement, alert: "This agreement has been countered. Please create a new counter offer instead of editing."
        return
      end

      unless (@agreement.pending? && current_user.id == @agreement.initiator_id) ||
             (@agreement.pending? && current_user.id == @agreement.other_party_id && !@agreement.is_counter_offer?)
        redirect_to @agreement, alert: "You cannot modify this agreement."
      end
    end

    def agreement_params
      params.require(:agreement).permit(
        :project_id, :other_party_id, :agreement_type, :payment_type,
        :start_date, :end_date, :tasks, :weekly_hours, :hourly_rate, :equity_percentage,
        :counter_to_id, :initiator_id, milestone_ids: []
      )
    end

    def authorize_agreement_action
      action = params[:action].to_sym
      authorize! action, @agreement
    end

    def details_link
      <<~HTML
        <a href="#{agreement_path(@agreement)}" class="p-1 bg-white text-gray-500">View Details</a>
      HTML
    end
end
