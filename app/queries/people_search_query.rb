# Query object for searching and filtering users (people)
# Uses Ransack for declarative filtering
class PeopleSearchQuery
  def initialize(current_user, params = {})
    @current_user = current_user
    @params = normalize_params(params)
    @q = build_ransack_params
  end

  attr_reader :q

  def results
    scope = base_scope
    scope = apply_project_filter(scope)
    apply_ransack(scope)
  end

  def search_object(scope = User.all)
    scope.ransack(@q)
  end

  private

  def normalize_params(params)
    hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    hash.with_indifferent_access
  end

  def apply_ransack(scope)
    scope.ransack(@q).result(distinct: true)
         .includes(:projects, :initiated_agreements, :received_agreements)
  end

  def base_scope
    User.all
  end

  def apply_project_filter(scope)
    return scope unless @params[:project_id].present?
    scope.joins(:projects).where(projects: { id: @params[:project_id] })
  end

  def build_ransack_params
    q = {}

    # Text search on name and bio
    if @params[:search].present?
      q[:first_name_or_last_name_or_bio_cont] = @params[:search]
    end

    q
  end
end
