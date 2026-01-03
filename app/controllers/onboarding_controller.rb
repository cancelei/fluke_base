# frozen_string_literal: true

# Handles AI productivity onboarding and insights navigation.
#
# Provides endpoints for:
# - Viewing detailed insights per metric type
# - Marking insights as seen (for dismissal)
# - Tracking onboarding progress
#
class OnboardingController < ApplicationController
  before_action :set_service
  before_action :set_project

  # GET /dashboard/insights
  # Shows all available insights in detail
  def insights
    @insights = @service.full_summary
    @onboarding = @service.onboarding_summary
  end

  # GET /dashboard/insights/:type
  # Shows detailed view for a specific insight type
  def show
    @type = params[:type].to_sym
    @insight = insight_for_type(@type)

    unless @insight
      redirect_to dashboard_path, alert: "Insight not found"
      return
    end

    # Mark the intro as seen when viewing detail
    @service.mark_insight_seen("#{@type}_intro")
  end

  # POST /dashboard/insights/mark_seen
  # Marks an insight as seen (for dismissal via Turbo)
  def mark_seen
    insight_key = params[:insight_key]

    if insight_key.present?
      @service.mark_insight_seen(insight_key)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def set_service
    @service = AiInsightsService.new(user: current_user, project: @project)
  end

  def set_project
    @project = current_user.selected_project || current_user.projects.order(:created_at).first
  end

  def insight_for_type(type)
    case type
    when :time_saved
      {
        type:,
        title: "Time Saved by AI",
        summary: @service.time_saved_summary(period: period_param),
        description: time_saved_description
      }
    when :code_contribution
      {
        type:,
        title: "Code Contributions",
        summary: @service.code_contribution_summary(period: period_param),
        description: code_contribution_description
      }
    when :task_velocity
      {
        type:,
        title: "Task Velocity",
        summary: @service.task_velocity_summary(period: period_param),
        description: task_velocity_description
      }
    when :token_efficiency
      {
        type:,
        title: "Token Usage",
        summary: @service.token_efficiency_summary(period: period_param),
        description: token_efficiency_description
      }
    end
  end

  def period_param
    params[:period]&.to_sym || :week
  end

  def time_saved_description
    <<~DESC
      This metric estimates time saved by using AI assistance compared to
      manual development. It's calculated based on tool usage patterns and
      industry-standard time multipliers for different development tasks.
    DESC
  end

  def code_contribution_description
    <<~DESC
      Tracks code changes made during AI-assisted sessions. Includes
      lines added and removed, files changed, and commits attributed
      to AI-assisted development.
    DESC
  end

  def task_velocity_description
    <<~DESC
      Measures your task completion rate when using AI tools. Tracks
      WeDo tasks created and completed, helping you understand your
      productivity patterns.
    DESC
  end

  def token_efficiency_description
    <<~DESC
      Shows your AI token usage and estimated costs. Helps you understand
      how efficiently you're using AI assistance and track usage patterns
      over time.
    DESC
  end
end
