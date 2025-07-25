module UserAgreements
  extend ActiveSupport::Concern

  included do
    # All agreements where user is a party
    has_many :initiated_agreements, class_name: "Agreement",
             through: :agreement_participants, source: :agreement
    has_many :received_agreements, class_name: "Agreement",
             through: :agreement_participants, source: :agreement
  end

  # Agreements where user is the entrepreneur (project owner)
  def my_agreements
    Agreement.joins(:project)
            .where("projects.user_id = ?", id)
  end

  # Agreements where user is the mentor/co-founder (not project owner)
  def other_party_agreements
    Agreement.joins(:project)
            .joins(:agreement_participants)
            .where("agreement_participants.user_id = ? AND projects.user_id != ?",
                  id, id)
  end

  # Alias for clarity when user is a mentor
  def agreements_as_mentor
    other_party_agreements
  end

  # Alias for clarity when user is an entrepreneur
  def agreements_as_entrepreneur
    my_agreements
  end

  def all_agreements
    Agreement.joins(:agreement_participants).where(agreement_participants: { user_id: id })
  end

  def mentor_projects
    Project.includes(:agreements)
           .joins(agreements: :agreement_participants)
           .where(agreement_participants: { user_id: id, is_initiator: true })
           .or(Project.joins(agreements: :agreement_participants)
                   .where(agreement_participants: { user_id: id, is_initiator: false }))
  end
end
