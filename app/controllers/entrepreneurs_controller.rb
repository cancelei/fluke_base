class EntrepreneursController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entrepreneur, only: [ :show, :message, :propose_agreement ]

  def explore
    @entrepreneurs = User.with_role(Role::ENTREPRENEUR).includes(:projects, :my_agreements)
  end

  def show
    # @entrepreneur is set by before_action
  end

  def message
    # Find or create a conversation between current_user and the entrepreneur
    @conversation = Conversation.between(current_user.id, @entrepreneur.id)
    redirect_to conversation_path(@conversation)
  end

  def propose_agreement
    # Only mentors can propose agreements to entrepreneurs
    @projects = current_user.projects

    unless selected_project
      redirect_to projects_path, alert: "Please select a project before proposing an agreement."
      return
    end

    # Create a new agreement with the entrepreneur
    @agreement = Agreement.new(
      initiator_id: current_user.id,
      other_party_id: @entrepreneur.id,
      status: Agreement::PENDING
    )

    # Redirect to the new agreement form with entrepreneur pre-filled
    redirect_to new_agreement_path(
      other_party_id: @entrepreneur.id,
      project_id: selected_project.id
    )
  end

  private

  def set_entrepreneur
    @entrepreneur = User.find(params[:id])
  end

  def selected_project
    # Try to get selected project from session or current_user helper
    @selected_project ||= begin
      if session[:selected_project_id]
        Project.find_by(id: session[:selected_project_id])
      elsif current_user.respond_to?(:selected_project)
        current_user.selected_project
      end
    end
  end
end
