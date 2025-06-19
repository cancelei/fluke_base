class MilestonesController < ApplicationController
  before_action :set_project
  before_action :set_milestone, only: [ :show, :edit, :update, :destroy, :confirm ]

  def index
    @milestones = @project.milestones.order(due_date: :asc)
  end

  def show
  end

  def new
    @milestone = @project.milestones.new
  end

  def create
    @milestone = @project.milestones.new(milestone_params)

    if @milestone.save
      redirect_to project_path(@project), notice: "Milestone was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @milestone.update(milestone_params)
      redirect_to project_path(@project), notice: "Milestone was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @milestone.destroy
    redirect_to project_path(@project), notice: "Milestone was successfully deleted."
  end

  def confirm
    if @milestone.update(status: Milestone::COMPLETED)
      redirect_to agreement_time_logs_path(@milestone.project.agreements.first), notice: "Milestone was successfully marked as completed."
    else
      redirect_to agreement_time_logs_path(@milestone.project.agreements.first), alert: "Failed to mark milestone as completed."
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "Project not found or you don't have access to it."
  end

  def set_milestone
    @milestone = @project.milestones.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to project_path(@project), alert: "Milestone not found."
  end

  def milestone_params
    params.require(:milestone).permit(:title, :description, :due_date, :status)
  end
end
