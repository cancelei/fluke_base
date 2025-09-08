class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]

  def index
    @projects = current_user.projects.includes(:user, :milestones, :agreements).order(created_at: :desc)
  end

  def explore
    @projects = ProjectSearchQuery.new(current_user, params).results
  end

  def show
    authorize! :read, @project
    @milestones = @project.milestones.includes(:time_logs).order(created_at: :desc)

    # Check if the current user has an agreement with the project
    @has_agreement = @project.agreements.active.joins(:agreement_participants)
      .exists?(agreement_participants: { user_id: current_user.id })

    # Load suggested mentors only for project owner
    if current_user.id == @project.user_id
      @suggested_mentors = User.with_role(:mentor)
                             .includes(:roles)
                             .where.not(id: @project.agreements.joins(:agreement_participants)
                                                                      .pluck("agreement_participants.user_id"))
                             .limit(3)
    else
      @suggested_mentors = []
    end

    # Update the selected project in the session
    if current_user && current_user.projects.include?(@project)
      ProjectSelectionService.new(current_user, session, @project.id).call
      @selected_project = @project
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @project }
    end
  end

  def new
    unless current_user.has_role?(Role::ENTREPRENEUR) && current_user.onboarded_for?(Role::ENTREPRENEUR)
      # Add Entrepreneur role if not present
      session[:comes_from_project_new] = true
      current_user.add_role("Entrepreneur") unless current_user.has_role?("Entrepreneur")
      # Redirect to entrepreneur onboarding
      redirect_to onboarding_entrepreneur_path, notice: "Please complete your entrepreneur profile before creating a project."
      return
    end

    @project_form = ProjectForm.new(user_id: current_user.id)
  end

  def create
    @project_form = ProjectForm.new(project_params.merge(user_id: current_user.id))

    if @project_form.save
      @project = @project_form.project
      GithubFetchBranchesJob.perform_later(@project.id, current_user.github_token)
      redirect_to @project, notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @project

    @project_form = ProjectForm.new(
      name: @project.name,
      description: @project.description,
      stage: @project.stage,
      category: @project.category,
      current_stage: @project.current_stage,
      target_market: @project.target_market,
      funding_status: @project.funding_status,
      team_size: @project.team_size,
      collaboration_type: @project.collaboration_type,
      repository_url: @project.repository_url,
      project_link: @project.project_link,
      public_fields: @project.public_fields,
      user_id: @project.user_id
    )
  end

  def update
    authorize! :update, @project

    @project_form = ProjectForm.new(project_params.merge(user_id: @project.user_id))

    if @project_form.valid?
      @project_form.update_project(@project)
      redirect_to @project, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    current_user.update(selected_project_id: nil) if current_user.selected_project_id == @project.id
    authorize! :destroy, @project
    @project.destroy
    redirect_to projects_path, notice: "Project was successfully deleted."
  end

  private

  def set_project
    @project = Project.includes(:user, :milestones, agreements: :agreement_participants).find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :stage, :category, :current_stage, :target_market, :funding_status, :team_size, :collaboration_type, :repository_url, :project_link, public_fields: [])
  end
end
