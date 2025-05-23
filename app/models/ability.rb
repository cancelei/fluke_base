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
    can :read, Project if user.has_role?(:mentor)

    # Agreements
    can :read, Agreement do |agreement|
      agreement.entrepreneur_id == user.id || agreement.mentor_id == user.id
    end

    can :create, Agreement do |agreement|
      # Entrepreneurs can create agreements for their projects or with other entrepreneurs
      # Mentors can create agreements if they're initiating it
      if agreement.project.present?
        agreement.project.user_id == user.id ||
        (user.has_role?(:mentor) && agreement.mentor_id == user.id) ||
        (
          user.has_role?(:entrepreneur) &&
          agreement.entrepreneur_id == user.id &&
          agreement.mentor_id.present? &&
          User.find_by(id: agreement.mentor_id)&.has_role?(:entrepreneur)
        )
      else
        true # Allow creation without project for testing
      end
    end

    can :edit, Agreement do |agreement|
      # Allow editing if:
      # 1. User is the initiator of the latest counter offer
      agreement.latest_counter_offer&.initiator_id == user.id && !agreement.countered?
    end

    # Check if agreement has counter offer from another entrepreneur
    can :has_counter_offer_from_entrepreneur, Agreement do |agreement|
      agreement.counter_offers.exists?(mentor_id: agreement.entrepreneur_id)
    end

    # Check if agreement has counter offer from mentor
    can :has_counter_offer_from_mentor, Agreement do |agreement|
      agreement.counter_offers.exists?(entrepreneur_id: agreement.mentor_id)
    end

    can :accept, Agreement do |agreement|
      # Only the receiver can accept a pending agreement
      agreement.pending? && agreement.initiator_id != user.id
    end

    can :reject, Agreement do |agreement|
      # Only the receiver can reject a pending agreement
      agreement.pending? && agreement.initiator_id != user.id
    end

    can :cancel, Agreement do |agreement|
      # Either party can cancel while pending
      agreement.pending? && (
        agreement.entrepreneur_id == user.id ||
        agreement.mentor_id == user.id
      )
    end

    can :counter_offer, Agreement do |agreement|
      # Only the receiver (mentor or entrepreneur) can make a counter offer to a pending agreement
      last_initiator = agreement.counter_offers.order(created_at: :desc).first&.initiator_id
      agreement.pending? && (
        (agreement.mentor_id == user.id && agreement.entrepreneur_id != user.id) ||
        (agreement.entrepreneur_id == user.id && agreement.mentor_id != user.id)
      ) && ((last_initiator.present? && last_initiator != user.id) || agreement.initiator_id != user.id)
    end

    can :complete, Agreement do |agreement|
      # Allow both entrepreneur and mentor to complete
      agreement.entrepreneur_id == user.id || agreement.mentor_id == user.id
    end

    # Meetings
    can :manage, Meeting do |meeting|
      meeting.agreement.entrepreneur_id == user.id || meeting.agreement.mentor_id == user.id
    end
  end
end
