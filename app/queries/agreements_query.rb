# Query object for filtering and searching agreements
# Uses Ransack for declarative filtering
class AgreementsQuery
  def initialize(current_user, params = {})
    @current_user = current_user
    @params = normalize_params(params)
    @q = build_ransack_params
  end

  attr_reader :q

  def my_agreements
    base = @current_user.my_agreements
                        .with_project_and_users
                        .with_meetings
                        .recent_first
    apply_ransack(base)
  end

  def other_party_agreements
    base = @current_user.other_party_agreements
                        .with_project_and_users
                        .with_meetings
                        .recent_first
    apply_ransack(base)
  end

  def search_object(base_scope = Agreement.all)
    base_scope.ransack(@q)
  end

  # Helper methods for filter options
  def self.status_options
    [
      ["All Statuses", ""],
      ["Pending", "pending"],
      ["Accepted", "accepted"],
      ["Completed", "completed"],
      ["Rejected", "rejected"],
      ["Cancelled", "cancelled"],
      ["Countered", "countered"]
    ]
  end

  def self.agreement_type_options
    [
      ["All Types", ""],
      ["Mentorship", "mentorship"],
      ["Co-Founder", "co_founder"]
    ]
  end

  def active_filters?
    @params[:project_id].present? ||
    @params[:status].present? ||
    @params[:agreement_type].present? ||
    @params[:start_date_from].present? ||
    @params[:start_date_to].present? ||
    @params[:end_date_from].present? ||
    @params[:end_date_to].present? ||
    @params[:search].present?
  end

  def active_filters_count
    count = 0
    count += 1 if @params[:project_id].present?
    count += 1 if @params[:status].present?
    count += 1 if @params[:agreement_type].present?
    count += 1 if @params[:start_date_from].present? || @params[:start_date_to].present?
    count += 1 if @params[:end_date_from].present? || @params[:end_date_to].present?
    count += 1 if @params[:search].present?
    count
  end

  def project_filter_name
    return nil unless @params[:project_id].present?
    Project.find_by(id: @params[:project_id])&.name
  end

  def check_duplicate_agreement(other_party_id, project_id)
    AgreementDuplicateChecker.new(
      user1_id: @current_user.id,
      user2_id: other_party_id,
      project_id: project_id
    ).find_duplicate
  end

  def existing_agreements_for_project(project)
    project.agreements.where(status: [Agreement::ACCEPTED, Agreement::PENDING])
  end

  private

  def normalize_params(params)
    hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    hash.with_indifferent_access
  end

  def apply_ransack(relation)
    relation.ransack(@q).result(distinct: true)
  end

  def build_ransack_params
    q = {}

    # Project filter
    q[:project_id_eq] = @params[:project_id] if @params[:project_id].present?

    # Status filter - map to database values
    if @params[:status].present?
      status_map = {
        "pending" => "Pending",
        "accepted" => "Accepted",
        "completed" => "Completed",
        "rejected" => "Rejected",
        "cancelled" => "Cancelled",
        "countered" => "Countered"
      }
      q[:status_eq] = status_map[@params[:status]] || @params[:status]
    end

    # Agreement type filter
    if @params[:agreement_type].present?
      type_map = {
        "mentorship" => "Mentorship",
        "co_founder" => "Co-Founder"
      }
      q[:agreement_type_eq] = type_map[@params[:agreement_type]] || @params[:agreement_type]
    end

    # Date range filters
    q[:start_date_gteq] = parse_date(@params[:start_date_from]) if @params[:start_date_from].present?
    q[:start_date_lteq] = parse_date(@params[:start_date_to]) if @params[:start_date_to].present?
    q[:end_date_gteq] = parse_date(@params[:end_date_from]) if @params[:end_date_from].present?
    q[:end_date_lteq] = parse_date(@params[:end_date_to]) if @params[:end_date_to].present?

    # Text search - uses Ransack's association searching
    if @params[:search].present?
      q[:project_name_or_users_first_name_or_users_last_name_cont] = @params[:search]
    end

    q
  end

  def parse_date(date_string)
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end
end
