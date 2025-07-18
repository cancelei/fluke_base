class MentorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mentor, only: [ :show, :message, :propose_agreement ]
  def explore
    @mentors = User.with_role(Role::MENTOR)
                   .where.not(id: current_user.id)
                   .includes(:user_roles, :roles)
                   .page(params[:page]).per(12)
  end

  def show
    @conversation = Conversation.between(current_user.id, @mentor.id)

    # Check if current user is an entrepreneur to enable agreement proposal
    @can_propose_agreement = current_user.has_role?(Role::ENTREPRENEUR)
  end

  def message
    @conversation = Conversation.between(current_user.id, @mentor.id)
    redirect_to conversation_path(@conversation)
  end

  def propose_agreement
    # Find projects owned by the current user
    @projects = current_user.projects

    # Check if a project is selected
    unless selected_project
      redirect_to projects_path, alert: "Please select a project before proposing an agreement."
      return
    end

    # Create a new agreement with the mentor
    @agreement = Agreement.new(
      other_party_id: @mentor.id,
      initiator_id: current_user.id,
      status: Agreement::PENDING
    )

    # Redirect to the new agreement form with mentor pre-filled
    redirect_to new_agreement_path(
      other_party_id: @mentor.id,
      project_id: selected_project.id
    )
  end

  private

  def set_mentor
    @mentor = User.with_role(Role::MENTOR).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to explore_mentors_path, alert: "Mentor not found"
  end
end
