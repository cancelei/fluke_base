# Query object for searching and filtering projects
# Uses Ransack for declarative filtering
class ProjectSearchQuery
  def initialize(user, params = {})
    @user = user
    @params = normalize_params(params)
    @q = build_ransack_params
  end

  attr_reader :q

  def results
    apply_ransack(base_scope)
  end

  # Alternative method for authenticated users to see their own stealth projects
  def results_including_user_stealth_projects
    apply_ransack(base_scope_with_user_stealth)
  end

  def search_object(scope = Project.all)
    scope.ransack(@q)
  end

  private

  def normalize_params(params)
    hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    hash.with_indifferent_access
  end

  def apply_ransack(scope)
    scope.ransack(@q).result(distinct: true).order(created_at: :desc)
  end

  def base_scope
    Project.joins(:user).publicly_visible
  end

  def base_scope_with_user_stealth
    if @user.present?
      Project.joins(:user)
             .where("projects.stealth_mode = false OR projects.user_id = ?", @user.id)
    else
      base_scope
    end
  end

  def build_ransack_params
    q = {}

    # Collaboration type filter
    if @params[:collaboration_type].present?
      case @params[:collaboration_type]
      when "mentor"
        q[:collaboration_type_in] = [Project::SEEKING_MENTOR, Project::SEEKING_BOTH]
      when "co_founder"
        q[:collaboration_type_in] = [Project::SEEKING_COFOUNDER, Project::SEEKING_BOTH]
      end
    end

    # Category filter
    q[:category_eq] = @params[:category] if @params[:category].present?

    # Text search
    q[:name_or_description_cont] = @params[:search] if @params[:search].present?

    q
  end
end
