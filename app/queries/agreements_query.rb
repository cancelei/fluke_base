class AgreementsQuery
  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def my_agreements
    @current_user.my_agreements
                 .includes(:project, :initiator, :other_party)
                 .order(created_at: :desc)
  end

  def other_party_agreements
    @current_user.other_party_agreements
                 .includes(:project, :initiator, :other_party)
                 .order(created_at: :desc)
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

  def check_duplicate_agreement(other_party_id, project_id)
    Agreement.where(
      other_party_id: other_party_id,
      project_id: project_id,
      initiator_id: @current_user.id
    ).where(status: [ Agreement::ACCEPTED, Agreement::PENDING ]).first
  end

  def existing_agreements_for_project(project)
    project.agreements.where(status: [ Agreement::ACCEPTED, Agreement::PENDING ])
  end
end
