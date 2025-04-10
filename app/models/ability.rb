# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the user here
    return unless user.present?

    # Admin can do everything
    can :manage, :all if user.has_role?(:admin)

    # Projects
    can :read, Project, user_id: user.id
    can :manage, Project, user_id: user.id

    # Allow mentors to see projects they have active agreements with
    can :read, Project do |project|
      project.agreements.active.where(mentor_id: user.id).exists? ||
      project.agreements.completed.where(mentor_id: user.id).exists?
    end

    # Allow mentors to explore all projects
    can :explore, Project if user.has_role?(:mentor)

    # Agreements
    can :read, Agreement, entrepreneur_id: user.id
    can :manage, Agreement, entrepreneur_id: user.id
    can :read, Agreement, mentor_id: user.id

    # Allow mentors to create agreements (for initiating)
    can :create, Agreement if user.has_role?(:mentor)

    # Agreement actions
    can :accept, Agreement do |agreement|
      agreement.pending? && agreement.mentor_id == user.id
    end

    can :reject, Agreement do |agreement|
      agreement.pending? && agreement.mentor_id == user.id
    end

    can :complete, Agreement do |agreement|
      agreement.active? && (agreement.entrepreneur_id == user.id || agreement.mentor_id == user.id)
    end

    can :cancel, Agreement do |agreement|
      agreement.pending? && agreement.entrepreneur_id == user.id
    end

    can :counter_offer, Agreement do |agreement|
      agreement.pending? && (agreement.entrepreneur_id == user.id || agreement.mentor_id == user.id)
    end

    # Meetings
    can :manage, Meeting do |meeting|
      meeting.agreement.entrepreneur_id == user.id || meeting.agreement.mentor_id == user.id
    end
  end
end
