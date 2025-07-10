class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :time_logs ]

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
    @has_agreement = @project.agreements.active.exists?([
      "(initiator_id = :user_id OR other_party_id = :user_id)",
      { user_id: current_user.id }
    ]) || @project.agreements.pending.exists?([
      "(initiator_id = :user_id OR other_party_id = :user_id)",
      { user_id: current_user.id }
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
      GithubFetchBranchesJob.perform_later(@project.id, current_user.github_token)
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

  def time_logs
    @owner = @project.user_id == current_user.id
    # Set the selected date or default to today
    @selected_date = params[:date].present? ? Date.parse(params[:date]) : Date.current

    # Get the date range for the carousel (3 days before and after selected date)
    @date_range = (@selected_date - 3.days)..(@selected_date + 3.days)

    @milestones = Milestone.where(project_id: @project.id)
    @users = User.joins(:time_logs).where(time_logs: { milestone_id: @milestones.ids }).distinct

    @time_logs = TimeLog.where(milestone: @milestones)
    @time_logs = @time_logs.includes(:milestone, :user)
                           .where("DATE(started_at) = '#{@selected_date}'")
                           .order(started_at: :desc)

    @milestones_pending_confirmation = @milestones
                                         .includes(:time_logs)
                                         .where(status: "in_progress", time_logs: { status: "completed" })
    @time_logs_completed = @milestones
                            .includes(:time_logs)
                            .where(status: "completed", time_logs: { status: "completed" })
                            .where("DATE(time_logs.started_at) = ?", @selected_date)

    @time_logs_manual = TimeLog.where(milestone_id: nil, user_id: @users.ids)
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :stage, :category, :current_stage, :target_market, :funding_status, :team_size, :collaboration_type, :repository_url, public_fields: [])
  end
end
