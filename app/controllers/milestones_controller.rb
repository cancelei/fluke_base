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
      respond_to do |format|
        format.turbo_stream do
          # Reload data for time_logs context if coming from time tracking
          if request.referer&.include?("time_logs")
            # Update relevant sections for time_logs page
            reload_time_logs_data
            render turbo_stream: [
              turbo_stream.remove("milestone_#{@milestone.id}_pending_row"),
              turbo_stream.update("completed_tasks_section",
                partial: "time_logs/completed_tasks_section",
                locals: {
                  time_logs_completed: @time_logs_completed,
                  project: @project,
                  owner: @owner
                }
              ),
              turbo_stream.update("pending_confirmation_section",
                partial: "time_logs/pending_confirmation_section",
                locals: {
                  milestones_pending_confirmation: @milestones_pending_confirmation,
                  project: @project,
                  owner: @owner
                }
              ),
              turbo_stream.update("flash_messages",
                partial: "shared/flash",
                locals: { notice: "Milestone confirmed successfully." }
              )
            ]
          else
                         # For other contexts, just show success message
                         render turbo_stream: turbo_stream.update("flash_messages",
               partial: "shared/flash_messages",
               locals: { notice: "Milestone confirmed successfully." }
             )
          end
        end
        format.html { redirect_back fallback_location: project_path(@project), notice: "Milestone confirmed successfully." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
                     render turbo_stream: turbo_stream.update("flash_messages",
             partial: "shared/flash_messages",
             locals: { alert: "Failed to mark milestone as completed." }
           )
        end
        format.html { redirect_back fallback_location: project_path(@project), alert: "Failed to mark milestone as completed." }
      end
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

  def reload_time_logs_data
    @owner = current_user.id == @project.user_id
    @milestones = (@owner ? @project.milestones : Milestone.where(id: @project.agreements.joins(:agreement_participants).where(agreement_participants: { user_id: current_user.id }).pluck(:milestone_ids).flatten))
    @milestones_pending_confirmation = @milestones
                                         .includes(:time_logs)
                                         .where(status: "in_progress", time_logs: { status: "completed" })
    @time_logs_completed = @milestones
                            .includes(:time_logs)
                            .where(status: Milestone::COMPLETED, time_logs: { status: "completed" })
  end
end
