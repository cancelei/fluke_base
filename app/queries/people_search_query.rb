class PeopleSearchQuery
  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def results
    scope = base_scope
    scope = filter_by_search_term(scope)
    scope = filter_by_role(scope)
    scope = filter_by_project(scope)
    # Removed exclude_current_user to allow users to see their own profile
    add_includes(scope)
  end

  private

  def base_scope
    User.all
  end

  def filter_by_search_term(scope)
    return scope unless @params[:search].present?

    scope.where("(first_name ILIKE :q OR last_name ILIKE :q OR bio ILIKE :q)", q: "%#{@params[:search]}%")
  end

  def filter_by_role(scope)
    # Role filtering removed with role system elimination
    scope
  end

  def filter_by_project(scope)
    return scope unless @params[:project_id].present?

    scope.joins(:projects).where(projects: { id: @params[:project_id] })
  end

  def exclude_current_user(scope)
    scope.where.not(id: @current_user.id)
  end

  def add_includes(scope)
    scope.distinct.includes(:projects, :initiated_agreements, :received_agreements)
  end
end
