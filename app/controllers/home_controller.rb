class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :stats ]

  def index
    # Get community counts for the landing page with optimized single query
    community_counts = get_community_counts
    @entrepreneur_count = community_counts[:creators]
    @mentor_count = community_counts[:contributors]
    @cofounder_count = community_counts[:collaborators]

    # Get real statistics for the landing page
    @total_agreements = Agreement.count
    @initiated_agreements_this_week = Agreement.where(created_at: 1.week.ago..Time.current).count
    @active_agreements = Agreement.active.count
    @completed_agreements = Agreement.completed.count

    # Calculate collaboration satisfaction (based on completed agreements vs total)
    # This is a placeholder - you might want to add a rating system later
    total_agreements = Agreement.where(agreement_type: Agreement::MENTORSHIP).count
    completed_agreements = Agreement.where(agreement_type: Agreement::MENTORSHIP, status: Agreement::COMPLETED).count
    @mentor_satisfaction_rate = total_agreements > 0 ? (completed_agreements.to_f / total_agreements * 100).round : 0

    # Calculate projects with agreements (proxy for "faster to market")
    projects_with_agreements = Project.joins(:agreements).where(agreements: { status: [ Agreement::ACCEPTED, Agreement::COMPLETED ] }).distinct.count
    total_projects = Project.count
    @projects_with_help_ratio = total_projects > 0 ? (projects_with_agreements.to_f / total_projects).round(1) : 0
  end

  def stats
    # Get fresh counts for all community types with optimized single query
    community_counts = get_community_counts
    @entrepreneur_count = community_counts[:creators]
    @mentor_count = community_counts[:contributors]
    @cofounder_count = community_counts[:collaborators]

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("entrepreneur_count", partial: "shared/count_display", locals: {
            type: "creators",
            count: @entrepreneur_count,
            default_count: 247
          }),
          turbo_stream.update("mentor_count", partial: "shared/count_display", locals: {
            type: "contributors",
            count: @mentor_count,
            default_count: 189
          }),
          turbo_stream.update("cofounder_count", partial: "shared/count_display", locals: {
            type: "collaborators",
            count: @cofounder_count,
            default_count: 73
          })
        ]
      end
      format.html { render partial: "stats", layout: false }
    end
  end


  private

  def get_community_counts
    # Since roles were removed, return total user counts for display
    # These represent the same community viewed through different lenses
    total_users = User.count

    {
      creators: total_users,
      contributors: total_users,
      collaborators: total_users
    }
  end
end
