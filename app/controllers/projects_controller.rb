class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @projects = pagy(current_user.projects
                              .includes(:user, :milestones, :agreements)
                              .order(created_at: :desc), items: 12)
  end

  def explore
    scope = ProjectSearchQuery.new(current_user, params).results
    @pagy, @projects = pagy(scope, items: 12)
  end

  def show
    authorize @project
    @milestones = @project.milestones.includes(:time_logs).order(created_at: :desc)

    # Check if the current user has an agreement with the project
    @has_agreement = @project.agreements.active.joins(:agreement_participants)
      .exists?(agreement_participants: { user_id: current_user.id })

    # Load suggested mentors only for project owner
    if current_user.id == @project.user_id
      @suggested_mentors = User.where.not(id: @project.agreements.joins(:agreement_participants)
                                                                      .pluck("agreement_participants.user_id"))
                             .limit(3)
    else
      @suggested_mentors = []
    end

    # Update the selected project in the session (only for project owners)
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
    @project_form = ProjectForm.new(user_id: current_user.id)
  end

  def create
    @project_form = ProjectForm.new(project_params.merge(user_id: current_user.id))

    if @project_form.save
      @project = @project_form.project
      GithubFetchBranchesJob.perform_later(@project.id, current_user.effective_github_token)
      redirect_to @project, notice: "Project was successfully created."
    else
      # Maintain stealth mode state on validation errors
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @project

    @project_form = ProjectForm.new(project_to_form_attributes(@project))
  end

  def update
    authorize @project

    # Pre-fill form with existing attributes to allow partial updates
    base_attrs = project_to_form_attributes(@project)
    @project_form = ProjectForm.new(base_attrs.merge(project_params).merge(user_id: @project.user_id))

    if @project_form.valid?
      @project_form.update_project(@project)
      GithubFetchBranchesJob.perform_later(@project.id, current_user.effective_github_token)
      redirect_to @project, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    current_user.update(selected_project_id: nil) if current_user.selected_project_id == @project.id
    authorize @project
    @project.destroy
    redirect_to projects_path, notice: "Project was successfully deleted."
  end

  private

  def form_builder_for(object)
    ActionView::Helpers::FormBuilder.new(:project, object, view_context, {})
  end

  def set_project = @project = Project.includes(:user, :milestones, agreements: :agreement_participants).find(params[:id])

  def project_params = params.require(:project).permit(:name, :description, :stage, :category, :current_stage, :target_market, :funding_status, :team_size, :collaboration_type, :repository_url, :project_link, :stealth_mode, :stealth_name, :stealth_description, :stealth_category, public_fields: [])

  def project_to_form_attributes(project)
    {
      name: project.name,
      description: project.description,
      stage: project.stage,
      category: project.category,
      current_stage: project.current_stage,
      target_market: project.target_market,
      funding_status: project.funding_status,
      team_size: project.team_size,
      collaboration_type: project.collaboration_type,
      repository_url: project.repository_url,
      project_link: project.project_link,
      public_fields: project.public_fields,
      user_id: project.user_id,
      stealth_mode: project.stealth_mode,
      stealth_name: project.stealth_name,
      stealth_description: project.stealth_description,
      stealth_category: project.stealth_category
    }
  end
end
