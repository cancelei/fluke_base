class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_project, only: [ :show, :edit, :update, :destroy ]

  def index
    @projects = current_user.projects.order(created_at: :desc)
  end

  def explore
    # Verify the user has the mentor role
    unless current_user.has_role?(:mentor)
      redirect_to projects_path, alert: "You need to be a mentor to explore available projects"
      return
    end

    # Base query for projects
    @projects = Project.joins(:user)
                      .where.not(user_id: current_user.id)
                      .where.not(id: Agreement.where(mentor_id: current_user.id).select(:project_id))
                      .order(created_at: :desc)

    # Filter by collaboration type if requested
    if params[:collaboration_type].present?
      case params[:collaboration_type]
      when "mentor"
        @projects = @projects.seeking_mentor
      when "co_founder"
        @projects = @projects.seeking_cofounder
      end
    else
      # By default, show projects that are seeking mentors
      @projects = @projects.seeking_mentor
    end

    # Filter by category if requested
    if params[:category].present?
      @projects = @projects.where(category: params[:category])
    end

    # Search by name or description
    if params[:search].present?
      @projects = @projects.where("name ILIKE ? OR description ILIKE ?",
                                "%#{params[:search]}%",
                                "%#{params[:search]}%")
    end

    @projects = @projects.page(params[:page]).per(12)
  end

  def show
    @has_agreement = current_user.id == @project.user_id ||
                    @project.agreements.where(mentor_id: current_user.id).exists?

    @is_mentor = current_user.has_role?(:mentor)

    @can_initiate_agreement = @is_mentor &&
                              !@has_agreement &&
                              current_user.id != @project.user_id

    if current_user.id == @project.user_id
      @suggested_mentors = User.with_role(:mentor)
                               .where.not(id: @project.agreements.pluck(:mentor_id))
                               .limit(5)
    end

    @milestones = @project.milestones.order(due_date: :asc)
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
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project was successfully deleted."
  end

  private

  def set_project
    # Allow mentors to access projects they don't own when viewing
    if current_user.has_role?(:mentor) && action_name == "show"
      @project = Project.find(params[:id])
    else
      @project = current_user.projects.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "Project not found or you don't have access to it."
  end

  def authorize_project
    # Allow project owners, admins, and mentors to view projects
    # Mentors can only view, not edit
    allowed_to_view = current_user.has_role?(:admin) ||
                     current_user.id == @project.user_id ||
                     (current_user.has_role?(:mentor) && action_name == "show")

    unless allowed_to_view
      redirect_to projects_path, alert: "You don't have access to this project."
      return
    end

    # For edit/update/destroy, only allow project owner or admin
    if [ "edit", "update", "destroy" ].include?(action_name)
      unless current_user.has_role?(:admin) || current_user.id == @project.user_id
        redirect_to project_path(@project), alert: "You don't have permission to modify this project."
      end
    end
  end

  def project_params
    params.require(:project).permit(:name, :description, :stage, :category, :current_stage, :target_market, :funding_status, :team_size, :collaboration_type)
  end
end
