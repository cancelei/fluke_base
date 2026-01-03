class MilestonesController < ApplicationController
  include MilestoneDataLoader
  include TurboStreamActions

  before_action :set_project
  before_action :set_milestone, only: [:show, :edit, :update, :destroy, :confirm, :enhancement_status, :enhancement_display]

  def index
    @milestones = @project.milestones.order(due_date: :asc)
  end

  def show
  end

  def new
    @milestone = @project.milestones.new
    @enhancement = nil # No enhancement initially, but container ready for AI suggestions
  end

  def create
    @milestone = @project.milestones.new(milestone_params)

    if @milestone.save
      redirect_to project_path(@project), notice: "Milestone was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @enhancement = @milestone.latest_enhancement
  end

  def update
    if @milestone.update(milestone_params)
      redirect_to project_path(@project), notice: "Milestone was successfully updated."
    else
      render :edit, status: :unprocessable_content
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
            data = {
              owner: @owner,
              milestones_pending_confirmation: @milestones_pending_confirmation,
              time_logs_completed: @time_logs_completed
            }

            render turbo_stream: [
              turbo_stream.remove("milestone_#{@milestone.id}_pending_row"),
              *update_milestone_data_streams(@project, data),
              update_flash_stream(notice: "Milestone confirmed successfully.")
            ]
          else
             # For other contexts, just show success message
             render turbo_stream: update_flash_stream(notice: "Milestone confirmed successfully.")
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

  def ai_enhance
    title = params[:title]
    description = params[:description]
    milestone_id = params[:milestone_id]

    if title.blank? && description.blank?
      return render turbo_stream: turbo_stream.update("flash_messages",
        partial: "shared/flash_messages",
        locals: { alert: "Please provide a title or description to enhance." }
      )
    end

    if milestone_id.present?
      # Handle existing milestone enhancement
      @milestone = @project.milestones.find(milestone_id)
      @enhancement = @milestone.milestone_enhancements.build(
        user: current_user,
        original_description: description || @milestone.description,
        enhancement_style: params[:enhancement_style] || "professional",
        status: "processing"
      )

      if @enhancement.save
        MilestoneEnhancementJob.perform_later(@enhancement.id, title, description)

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("ai-suggestion-container",
                partial: "milestones/ai_suggestion",
                locals: { enhancement: @enhancement, milestone: @milestone }
              ),
              turbo_stream.update("flash_messages",
                partial: "shared/flash_messages",
                locals: { notice: "AI enhancement started. Please wait..." }
              )
            ]
          end
        end
      end
    else
      # Handle new milestone enhancement (without creating milestone)
      begin
        service = MilestoneAiEnhancementService.new(@project)
        enhanced_description = service.augment_description(
          title:,
          description:
        )

        # Create a simple enhancement object for the UI (not saved to DB)
        @enhancement = EnhancementResult.new(
          id: nil,
          original_title: title,
          original_description: description,
          enhanced_description:,
          enhancement_style: params[:enhancement_style] || "professional",
          status: "completed",
          successful: true,
          direct_enhancement: true,
          created_at: Time.current,
          user: current_user
        )

        # Create a simple milestone object for the UI
        @milestone = MilestoneStub.new(id: nil)

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("ai-suggestion-container",
                partial: "milestones/ai_suggestion",
                locals: { enhancement: @enhancement, milestone: @milestone }
              ),
              turbo_stream.update("flash_messages",
                partial: "shared/flash_messages",
                locals: { notice: "AI enhancement completed!" }
              )
            ]
          end
        end
      rescue => e
        Rails.logger.error("Direct AI enhancement failed: #{e.message}")
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update("flash_messages",
              partial: "shared/flash_messages",
              locals: { alert: "AI enhancement failed. Please try again." }
            )
          end
        end
      end
    end
  rescue => e
    Rails.logger.error("AI enhancement failed: #{e.message}")
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("flash_messages",
          partial: "shared/flash_messages",
          locals: { alert: "AI enhancement failed. Please try again." }
        )
      end
    end
  end

  def apply_ai_enhancement
    @enhancement = MilestoneEnhancement.find(params[:enhancement_id])
    @milestone = @enhancement.milestone

    if @enhancement.successful? && @enhancement.enhanced_description.present?
      if @milestone.update(description: @enhancement.enhanced_description)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("milestone_description", @enhancement.enhanced_description),
              turbo_stream.update("ai-suggestion-container", ""),
              turbo_stream.update("flash_messages",
                partial: "shared/flash_messages",
                locals: { notice: "Enhancement applied successfully!" }
              )
            ]
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update("flash_messages",
              partial: "shared/flash_messages",
              locals: { alert: "Failed to apply enhancement." }
            )
          end
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash_messages",
            partial: "shared/flash_messages",
            locals: { alert: "Enhancement is not ready to be applied." }
          )
        end
      end
    end
  end

  def revert_ai_enhancement
    @enhancement = MilestoneEnhancement.find(params[:enhancement_id])
    @milestone = @enhancement.milestone

    if @milestone.update(description: @enhancement.original_description)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("milestone_description", @enhancement.original_description),
            turbo_stream.update("ai-suggestion-container", ""),
            turbo_stream.update("flash_messages",
              partial: "shared/flash_messages",
              locals: { notice: "Reverted to original description." }
            )
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash_messages",
            partial: "shared/flash_messages",
            locals: { alert: "Failed to revert enhancement." }
          )
        end
      end
    end
  end

  def discard_ai_enhancement
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("ai-suggestion-container", "")
      end
    end
  end

  def enhancement_status
    @enhancement = @milestone.latest_enhancement

    respond_to do |format|
      format.json do
        if @enhancement
          render json: {
            enhancement: {
              id: @enhancement.id,
              status: @enhancement.status,
              created_at: @enhancement.created_at,
              updated_at: @enhancement.updated_at
            }
          }
        else
          render json: { enhancement: nil }
        end
      end
    end
  end

  def enhancement_display
    @enhancement = @milestone.latest_enhancement

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("ai-suggestion-container",
          partial: "milestones/ai_suggestion",
          locals: { enhancement: @enhancement, milestone: @milestone }
        )
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
    data = load_milestone_data(@project, current_user)
    @owner = data[:owner]
    @milestones = data[:milestones]
    @milestones_pending_confirmation = data[:milestones_pending_confirmation]
    @time_logs_completed = data[:time_logs_completed]
  end
end
