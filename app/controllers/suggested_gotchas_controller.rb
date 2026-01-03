# frozen_string_literal: true

# Controller for reviewing auto-detected gotcha suggestions.
# Allows users to approve, dismiss, or edit suggestions before
# they become permanent ProjectMemory gotchas.
class SuggestedGotchasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :authorize_project_access!
  before_action :set_suggested_gotcha, only: [:show, :update, :destroy, :approve, :dismiss]

  # GET /projects/:project_id/suggested_gotchas
  def index
    @suggested_gotchas = @project.suggested_gotchas.recent

    # Filter by status if provided
    if params[:status].present? && SuggestedGotcha::STATUSES.include?(params[:status])
      @suggested_gotchas = @suggested_gotchas.where(status: params[:status])
    else
      # Default to showing pending items
      @suggested_gotchas = @suggested_gotchas.pending
    end

    # Group by trigger type for display
    @grouped_gotchas = @suggested_gotchas.group_by(&:trigger_type)

    respond_to do |format|
      format.html
      format.json { render json: @suggested_gotchas.map(&:to_api_hash) }
    end
  end

  # GET /projects/:project_id/suggested_gotchas/:id
  def show
    respond_to do |format|
      format.html
      format.json { render json: @suggested_gotcha.to_api_hash }
    end
  end

  # PATCH/PUT /projects/:project_id/suggested_gotchas/:id
  # Update the suggested content before approving
  def update
    if @suggested_gotcha.update(suggested_gotcha_params)
      respond_to do |format|
        format.html { redirect_to project_suggested_gotcha_path(@project, @suggested_gotcha), notice: "Suggestion updated." }
        format.turbo_stream { stream_toast_success("Suggestion updated.") }
        format.json { render json: @suggested_gotcha.to_api_hash }
      end
    else
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.turbo_stream { stream_toast_error("Failed to update suggestion.") }
        format.json { render json: { errors: @suggested_gotcha.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/:project_id/suggested_gotchas/:id
  # Permanently delete a suggestion
  def destroy
    @suggested_gotcha.destroy

    respond_to do |format|
      format.html { redirect_to project_suggested_gotchas_path(@project), notice: "Suggestion deleted." }
      format.turbo_stream do
        stream_toast_success("Suggestion deleted.")
        render turbo_stream: turbo_stream.remove(@suggested_gotcha)
      end
      format.json { head :no_content }
    end
  end

  # POST /projects/:project_id/suggested_gotchas/:id/approve
  # Approve the suggestion and create a ProjectMemory
  def approve
    unless @suggested_gotcha.reviewable?
      respond_to do |format|
        format.html { redirect_to project_suggested_gotchas_path(@project), alert: "This suggestion has already been reviewed." }
        format.turbo_stream { stream_toast_error("This suggestion has already been reviewed.") }
        format.json { render json: { error: "Already reviewed" }, status: :unprocessable_entity }
      end
      return
    end

    begin
      memory = @suggested_gotcha.approve!(
        user: current_user,
        content: params[:content],
        title: params[:title]
      )

      respond_to do |format|
        format.html { redirect_to project_suggested_gotchas_path(@project), notice: "Gotcha approved and saved!" }
        format.turbo_stream do
          stream_toast_success("Gotcha approved and saved!")
          render turbo_stream: turbo_stream.remove(@suggested_gotcha)
        end
        format.json { render json: { suggested_gotcha: @suggested_gotcha.to_api_hash, memory: memory.to_api_hash } }
      end
    rescue => e
      Rails.logger.error("Failed to approve suggestion: #{e.message}")

      respond_to do |format|
        format.html { redirect_to project_suggested_gotcha_path(@project, @suggested_gotcha), alert: "Failed to approve: #{e.message}" }
        format.turbo_stream { stream_toast_error("Failed to approve suggestion.") }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end

  # POST /projects/:project_id/suggested_gotchas/:id/dismiss
  # Dismiss the suggestion (won't be suggested again)
  def dismiss
    unless @suggested_gotcha.reviewable?
      respond_to do |format|
        format.html { redirect_to project_suggested_gotchas_path(@project), alert: "This suggestion has already been reviewed." }
        format.turbo_stream { stream_toast_error("This suggestion has already been reviewed.") }
        format.json { render json: { error: "Already reviewed" }, status: :unprocessable_entity }
      end
      return
    end

    @suggested_gotcha.dismiss!(user: current_user, reason: params[:reason])

    respond_to do |format|
      format.html { redirect_to project_suggested_gotchas_path(@project), notice: "Suggestion dismissed." }
      format.turbo_stream do
        stream_toast_info("Suggestion dismissed.")
        render turbo_stream: turbo_stream.remove(@suggested_gotcha)
      end
      format.json { render json: @suggested_gotcha.to_api_hash }
    end
  end

  private

  def set_project
    @project = current_user.projects.friendly.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    # Try to find through memberships
    @project = Project.joins(:project_memberships)
                      .where(project_memberships: { user: current_user, status: "accepted" })
                      .friendly.find(params[:project_id])
  end

  def authorize_project_access!
    unless can_manage_project?(@project)
      redirect_to dashboard_path, alert: "You don't have access to this project."
    end
  end

  def can_manage_project?(project)
    project.user == current_user ||
      project.project_memberships.accepted.exists?(user: current_user)
  end

  def set_suggested_gotcha
    @suggested_gotcha = @project.suggested_gotchas.find(params[:id])
  end

  def suggested_gotcha_params
    params.require(:suggested_gotcha).permit(:suggested_content, :suggested_title)
  end
end
