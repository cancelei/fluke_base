module MilestoneDataLoader
  extend ActiveSupport::Concern

  included do
    helper_method :load_milestone_data
  end

  def load_milestone_data(project, user, order: false)
    owner = user.id == project.user_id
    
    milestones_scope = if owner
      project.milestones
    else
      Milestone.where(id: project.agreements
                              .joins(:agreement_participants)
                              .where(agreement_participants: { user_id: user.id })
                              .pluck(:milestone_ids)
                              .flatten)
    end

    if order
      milestones_scope = milestones_scope.order(due_date: :asc, id: :asc)
    end

    milestones_pending_confirmation = milestones_scope
                                        .includes(:time_logs)
                                        .where(status: "in_progress", time_logs: { status: "completed" })

    time_logs_completed = milestones_scope
                            .includes(:time_logs)
                            .where(status: Milestone::COMPLETED, time_logs: { status: "completed" })

    {
      owner: owner,
      milestones: milestones_scope,
      milestones_pending_confirmation: milestones_pending_confirmation,
      time_logs_completed: time_logs_completed
    }
  end
end
