class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    # Real statistics for the landing page
    @stats = {
      total_users: User.count,
      total_projects: Project.count,
      total_agreements: Agreement.count,
      active_agreements: Agreement.active.count
    }
  end
end
