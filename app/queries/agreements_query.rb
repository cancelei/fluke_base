class AgreementsQuery
  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params.to_h.with_indifferent_access
  end

  def my_agreements
    agreements = @current_user.my_agreements
                              .with_project_and_users
                              .with_meetings
                              .recent_first
    apply_filters(agreements)
  end

  def other_party_agreements
    agreements = @current_user.other_party_agreements
                              .with_project_and_users
                              .with_meetings
                              .recent_first
    apply_filters(agreements)
  end

  def filter_by_status(my_agreements, other_party_agreements)
    status_filter = @params[:status]
    return [ my_agreements, other_party_agreements ] unless status_filter.present?

    case status_filter
    when "pending"
      [ my_agreements.pending, other_party_agreements.pending ]
    when "accepted"
      [ my_agreements.active, other_party_agreements.active ]
    when "completed"
      [ my_agreements.completed, other_party_agreements.completed ]
    when "rejected"
      [ my_agreements.rejected, other_party_agreements.rejected ]
    when "cancelled"
      [ my_agreements.cancelled, other_party_agreements.cancelled ]
    else
      [ my_agreements, other_party_agreements ]
    end
  end

  # New filtering methods
  def apply_filters(relation)
    relation = filter_by_status_new(relation)
    relation = filter_by_agreement_type(relation)
    relation = filter_by_date_range(relation)
    relation = filter_by_search(relation)
    relation
  end

  def filter_by_status_new(relation)
    return relation unless @params[:status].present?

    case @params[:status]
    when "pending"
      relation.pending
    when "accepted"
      relation.active
    when "completed"
      relation.completed
    when "rejected"
      relation.rejected
    when "cancelled"
      relation.cancelled
    when "countered"
      relation.countered
    else
      relation
    end
  end

  def filter_by_agreement_type(relation)
    return relation unless @params[:agreement_type].present?

    case @params[:agreement_type]
    when "mentorship"
      relation.mentorships
    when "co_founder"
      relation.co_founding
    else
      relation
    end
  end

  def filter_by_date_range(relation)
    relation = filter_by_start_date(relation)
    relation = filter_by_end_date(relation)
    relation
  end

  def filter_by_start_date(relation)
    if @params[:start_date_from].present?
      relation = relation.where("start_date >= ?", Date.parse(@params[:start_date_from]))
    end

    if @params[:start_date_to].present?
      relation = relation.where("start_date <= ?", Date.parse(@params[:start_date_to]))
    end

    relation
  rescue ArgumentError
    relation
  end

  def filter_by_end_date(relation)
    if @params[:end_date_from].present?
      relation = relation.where("end_date >= ?", Date.parse(@params[:end_date_from]))
    end

    if @params[:end_date_to].present?
      relation = relation.where("end_date <= ?", Date.parse(@params[:end_date_to]))
    end

    relation
  rescue ArgumentError
    relation
  end

  def filter_by_search(relation)
    return relation unless @params[:search].present?

    search_term = "%#{@params[:search]}%"
    relation.joins(:project, agreement_participants: :user)
            .where(
              "projects.name ILIKE ? OR users.first_name ILIKE ? OR users.last_name ILIKE ? OR CONCAT(users.first_name, ' ', users.last_name) ILIKE ?",
              search_term, search_term, search_term, search_term
            )
            .distinct
  end

  # Helper methods for filter options
  def self.status_options
    [
      [ "All Statuses", "" ],
      [ "Pending", "pending" ],
      [ "Accepted", "accepted" ],
      [ "Completed", "completed" ],
      [ "Rejected", "rejected" ],
      [ "Cancelled", "cancelled" ],
      [ "Countered", "countered" ]
    ]
  end

  def self.agreement_type_options
    [
      [ "All Types", "" ],
      [ "Mentorship", "mentorship" ],
      [ "Co-Founder", "co_founder" ]
    ]
  end

  def active_filters?
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
    count += 1 if @params[:status].present?
    count += 1 if @params[:agreement_type].present?
    count += 1 if @params[:start_date_from].present? || @params[:start_date_to].present?
    count += 1 if @params[:end_date_from].present? || @params[:end_date_to].present?
    count += 1 if @params[:search].present?
    count
  end

  def check_duplicate_agreement(other_party_id, project_id)
    Agreement.joins(:agreement_participants)
      .where(
        project_id: project_id,
        status: [ Agreement::ACCEPTED, Agreement::PENDING ]
      )
      .where(agreement_participants: { user_id: [ @current_user.id, other_party_id ] })
      .group("agreements.id")
      .having("COUNT(agreement_participants.id) = 2")
      .first
  end

  def existing_agreements_for_project(project)
    project.agreements.where(status: [ Agreement::ACCEPTED, Agreement::PENDING ])
  end
end
