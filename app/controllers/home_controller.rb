class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :stats ]

  def index
    # Get role counts for the landing page
    @entrepreneur_count = User.with_role(Role::ENTREPRENEUR).count
    @mentor_count = User.with_role(Role::MENTOR).count
    @cofounder_count = User.with_role(Role::CO_FOUNDER).count

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
    # Get updated role counts
    @entrepreneur_count = User.with_role(Role::ENTREPRENEUR).count
    @mentor_count = User.with_role(Role::MENTOR).count
    @cofounder_count = User.with_role(Role::CO_FOUNDER).count

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("entrepreneur_count", partial: "home/entrepreneur_count", locals: { count: @entrepreneur_count }),
          turbo_stream.replace("mentor_count", partial: "home/mentor_count", locals: { count: @mentor_count }),
          turbo_stream.replace("cofounder_count", partial: "home/cofounder_count", locals: { count: @cofounder_count })
        ]
      end
      format.html { render partial: "stats" }
    end
  end
end
