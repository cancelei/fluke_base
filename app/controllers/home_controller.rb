class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :stats ]

  def index
    # Get role counts for the landing page
    @entrepreneur_count = User.with_role(Role::ENTREPRENEUR).count
    @mentor_count = User.with_role(Role::MENTOR).count
    @cofounder_count = User.with_role(Role::CO_FOUNDER).count
  end

  def stats
    # Get updated role counts
    @entrepreneur_count = User.with_role(Role::ENTREPRENEUR).count
    @mentor_count = User.with_role(Role::MENTOR).count
    @cofounder_count = User.with_role(Role::CO_FOUNDER).count

    render turbo_stream: turbo_stream.replace("community_stats", partial: "stats")
  end
end
