class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :stats ]

  def index
    # Get role counts for the landing page with optimized single query
    role_counts = get_role_counts
    @entrepreneur_count = role_counts[:entrepreneur]
    @mentor_count = role_counts[:mentor]
    @cofounder_count = role_counts[:cofounder]

    # Get real statistics for the landing page
    @total_agreements = Agreement.count
    @initiated_agreements_this_week = Agreement.where(created_at: 1.week.ago..Time.current).count
    @active_agreements = Agreement.active.count
    @completed_agreements = Agreement.completed.count

    # Calculate mentor satisfaction (based on completed agreements vs total)
    # This is a placeholder - you might want to add a rating system later
    total_mentor_agreements = Agreement.where(agreement_type: Agreement::MENTORSHIP).count
    completed_mentor_agreements = Agreement.where(agreement_type: Agreement::MENTORSHIP, status: Agreement::COMPLETED).count
    @mentor_satisfaction_rate = total_mentor_agreements > 0 ? (completed_mentor_agreements.to_f / total_mentor_agreements * 100).round : 0

    # Calculate projects with agreements (proxy for "faster to market")
    projects_with_agreements = Project.joins(:agreements).where(agreements: { status: [ Agreement::ACCEPTED, Agreement::COMPLETED ] }).distinct.count
    total_projects = Project.count
    @projects_with_help_ratio = total_projects > 0 ? (projects_with_agreements.to_f / total_projects).round(1) : 0
  end

  def stats
    # Get fresh counts for all role types with optimized single query
    role_counts = get_role_counts
    @entrepreneur_count = role_counts[:entrepreneur]
    @mentor_count = role_counts[:mentor]
    @cofounder_count = role_counts[:cofounder]

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("entrepreneur_count", partial: "shared/count_display", locals: {
            type: "entrepreneur",
            count: @entrepreneur_count,
            default_count: 247
          }),
          turbo_stream.update("mentor_count", partial: "shared/count_display", locals: {
            type: "mentor",
            count: @mentor_count,
            default_count: 189
          }),
          turbo_stream.update("cofounder_count", partial: "shared/count_display", locals: {
            type: "cofounder",
            count: @cofounder_count,
            default_count: 73
          })
        ]
      end
      format.html { render partial: "stats", layout: false }
    end
  end

  private

  def get_role_counts
    # Single query to get all role counts efficiently
    counts = User.joins(:roles)
                 .where(roles: { name: [ Role::ENTREPRENEUR, Role::MENTOR, Role::CO_FOUNDER ] })
                 .group("roles.name")
                 .count

    {
      entrepreneur: counts[Role::ENTREPRENEUR] || 0,
      mentor: counts[Role::MENTOR] || 0,
      cofounder: counts[Role::CO_FOUNDER] || 0
    }
  end
end
