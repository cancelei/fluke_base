module UserAgreements
  extend ActiveSupport::Concern

  included do
    # All agreements where user is a party
    has_many :initiated_agreements, class_name: "Agreement",
             foreign_key: "initiator_id", dependent: :destroy
    has_many :received_agreements, class_name: "Agreement",
             foreign_key: "other_party_id", dependent: :destroy
  end

  # Agreements where user is the entrepreneur (project owner)
  def my_agreements
    Agreement.joins(:project)
            .where("projects.user_id = ?", id)
  end

  # Agreements where user is the mentor/co-founder (not project owner)
  def other_party_agreements
    Agreement.joins(:project)
            .where("(agreements.initiator_id = ? OR agreements.other_party_id = ?) AND projects.user_id != ?",
                  id, id, id)
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
    Agreement.where("initiator_id = ? OR other_party_id = ?", id, id)
  end

  def mentor_projects
    Project.includes(:agreements)
           .where(agreements: { initiator_id: id })
           .or(Project.includes(:agreements).where(agreements: { other_party_id: id }))
  end
end
