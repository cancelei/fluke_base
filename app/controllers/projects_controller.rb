class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]

  def index
    @projects = current_user.projects.order(created_at: :desc)
  end

  def explore
    @projects = ProjectSearchQuery.new(current_user, params).results
  end

  def show
    authorize! :read, @project
    @milestones = @project.milestones.order(created_at: :desc)

    # Check if the current user has an agreement with the project
    @has_agreement = @project.agreements.exists?([
      "(initiator_id = :user_id OR other_party_id = :user_id) AND status IN (:statuses)",
      { user_id: current_user.id, statuses: [ Agreement::ACCEPTED, Agreement::PENDING ] }
    ])

    # Load suggested mentors only for project owner
    if current_user.id == @project.user_id
      @suggested_mentors = User.with_role(:mentor)
                             .where.not(id: @project.agreements.pluck(:other_party_id))
                             .limit(3)
    else
      @suggested_mentors = []
    end
  end

  def new
    @project = Project.new
  end

  def create
    @project = current_user.projects.new(project_params)

    if @project.save
      redirect_to @project, notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @project
  end

  def update
    authorize! :update, @project
    if @project.update(project_params)
      redirect_to @project, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @project
    @project.destroy
    redirect_to projects_path, notice: "Project was successfully deleted."
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :stage, :category, :current_stage, :target_market, :funding_status, :team_size, :collaboration_type, :repository_url, public_fields: [])
  end
end
