class ProjectSearchQuery
  def initialize(user, params = {})
    @user = user
    @params = params
  end

  def results
    scope = base_scope
    scope = filter_by_collaboration_type(scope)
    scope = filter_by_category(scope)
    scope = search_by_text(scope)
    scope.page(@params[:page]).per(12)
  end

  private

  def base_scope
    Project.joins(:user)
           .order(created_at: :desc)
  end

  def filter_by_collaboration_type(scope)
    return scope.seeking_mentor unless @params[:collaboration_type].present?

    case @params[:collaboration_type]
    when "mentor"
      scope.seeking_mentor
    when "co_founder"
      scope.seeking_cofounder
    else
      scope
    end
  end

  def filter_by_category(scope)
    return scope unless @params[:category].present?
    scope.where(category: @params[:category])
  end

  def search_by_text(scope)
    return scope unless @params[:search].present?
    scope.where("name ILIKE ? OR description ILIKE ?",
               "%#{@params[:search]}%",
               "%#{@params[:search]}%")
  end
end
