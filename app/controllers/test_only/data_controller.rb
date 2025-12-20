class TestOnly::DataController < ApplicationController
  before_action :ensure_test_environment
  skip_forgery_protection

  # Requires an authenticated user (use /test_only/login first)
  def create_project
    unless user_signed_in?
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: "Login required" }
        format.json { render json: { ok: false, error: "unauthorized" }, status: :unauthorized }
      end
      return
    end

    name = params[:name].presence || "E2E Project #{SecureRandom.hex(3)}"
    description = params[:description].presence || "E2E seed project for Playwright tests"
    stage = params[:stage].presence || Project::IDEA

    project = Project.create!(
      user: current_user,
      name:,
      description:,
      stage:,
      category: nil,
      current_stage: nil,
      target_market: nil,
      funding_status: nil,
      team_size: nil,
      collaboration_type: nil,
      repository_url: nil,
      project_link: nil,
      public_fields: []
    )

    respond_to do |format|
      format.html { redirect_to projects_path, notice: "Project created for E2E" }
      format.json { render json: { ok: true, id: project.id, name: project.name } }
    end
  end

  # Creates a minimal Agreement between current_user (initiator) and other party.
  # Params: other_email (default: mentor@example.com), project_id OR project_name to create/find,
  #         type (Mentorship|Co-Founder), payment (Hourly|Equity|Hybrid)
  def create_agreement
    return unauthorized unless user_signed_in?

    other = find_or_create_user(params[:other_email].presence || "mentor@example.com", first_name: "Mentor", last_name: "User")

    project = if params[:project_id].present?
                Project.find_by(id: params[:project_id])
    elsif params[:project_name].present?
                current_user.projects.find_or_create_by!(
                  name: params[:project_name]
                ) do |p|
                  p.description = "E2E project for agreements"
                  p.stage = Project::IDEA
                end
    else
                current_user.projects.first || Project.create!(user: current_user, name: "E2E Project #{SecureRandom.hex(3)}", description: "E2E project", stage: Project::IDEA)
    end

    # Create one milestone to satisfy mentorship validation
    milestone = project.milestones.create!(title: "E2E Milestone", due_date: Date.today + 7, status: Milestone::PENDING)

    # Avoid duplicate pending/accepted agreements between the two users for this project
    existing = Agreement.joins(:agreement_participants)
                        .where(project_id: project.id, status: [Agreement::PENDING, Agreement::ACCEPTED])
                        .where(agreement_participants: { user_id: [current_user.id, other.id] })
                        .group("agreements.id")
                        .having("COUNT(agreement_participants.id) = 2")
                        .first
    if existing
      return render json: { ok: true, id: existing.id, status: existing.status, project_id: project.id }
    end

    type = params[:type].presence || Agreement::MENTORSHIP
    payment = params[:payment].presence || Agreement::HOURLY

    form = AgreementForm.new(
      project_id: project.id,
      initiator_user_id: current_user.id,
      other_party_user_id: other.id,
      agreement_type: type,
      payment_type: payment,
      start_date: Date.today,
      end_date: Date.today + 7,
      tasks: "Scoped E2E tasks",
      weekly_hours: 5,
      hourly_rate: 10,
      equity_percentage: 0,
      milestone_ids: [milestone.id]
    )

    form.save
    agreement = form.agreement

    respond_to do |format|
      format.html { redirect_to agreements_path, notice: "Agreement created for E2E" }
      format.json { render json: { ok: true, id: agreement.id, status: agreement.status, project_id: project.id } }
    end
  rescue => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end

  # Creates a conversation with other party and an optional seeded message.
  # Params: other_email (default: mentor@example.com), body (default: "Hello E2E")
  def create_conversation
    return unauthorized unless user_signed_in?

    other = find_or_create_user(params[:other_email].presence || "mentor@example.com", first_name: "Mentor", last_name: "User")
    conversation = Conversation.between(current_user.id, other.id)
    body = params[:body].presence || "Hello E2E"
    conversation.messages.create!(user: current_user, body:)

    respond_to do |format|
      format.html { redirect_to conversation_path(conversation), notice: "Conversation created for E2E" }
      format.json { render json: { ok: true, id: conversation.id, body: } }
    end
  end

  private

  def ensure_test_environment
    head :not_found unless Rails.env.test?
  end

  def unauthorized
    respond_to do |format|
      format.html { redirect_to new_user_session_path, alert: "Login required" }
      format.json { render json: { ok: false, error: "unauthorized" }, status: :unauthorized }
    end
  end

  def find_or_create_user(email, first_name: "E2E", last_name: "User")
    user = User.find_by(email:)
    return user if user
    password = "Password!123"
    user = User.new(
      email:,
      password:,
      password_confirmation: password,
      first_name:,
      last_name:
    )
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    user.save!
    user
  end
end
