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
      project.agreements.active.where(other_party_id: user.id).exists? ||
      project.agreements.completed.where(other_party_id: user.id).exists?
    end

    # Allow mentors to explore all projects
    can :explore, Project if user.has_role?(:mentor)
    can :read, Project if user.has_role?(:mentor)

    # Agreements
    can :read, Agreement do |agreement|
      agreement.initiator_id == user.id || agreement.other_party_id == user.id
    end

    can :create, Agreement do |agreement|
      true
    end

    can :edit, Agreement do |agreement|
      # Allow editing if:
      # 1. User is the initiator of the latest counter offer
      agreement.latest_counter_offer&.initiator_id == user.id && !agreement.countered?
    end

    # Check if agreement has counter offer from another entrepreneur
    can :has_counter_offer, Agreement do |agreement|
      agreement.counter_offers.exists?(other_party_id: agreement.initiator_id)
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
        agreement.initiator_id == user.id ||
        agreement.other_party_id == user.id
      )
    end

    can :counter_offer, Agreement do |agreement|
      # Only the receiver (mentor or entrepreneur) can make a counter offer to a pending agreement
      last_initiator = agreement.counter_offers.order(created_at: :desc).first&.initiator_id
      agreement.pending? && (
        (agreement.other_party_id == user.id && agreement.initiator_id != user.id) ||
        (agreement.initiator_id == user.id && agreement.other_party_id != user.id)
      ) && ((last_initiator.present? && last_initiator != user.id) || agreement.initiator_id != user.id)
    end

    can :complete, Agreement do |agreement|
      # Allow both entrepreneur and mentor to complete
      agreement.initiator_id == user.id || agreement.other_party_id == user.id
    end

    # Meetings
    can :manage, Meeting do |meeting|
      meeting.agreement.initiator_id == user.id || meeting.agreement.other_party_id == user.id
    end
  end
end
