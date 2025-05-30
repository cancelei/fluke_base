# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the user here
    return unless user.present?

    # Admin can do everything
    can :manage, :all if user.has_role?(:admin)

    define_project_abilities(user)
    define_agreement_abilities(user)
    define_meeting_abilities(user)
  end

  private

  def define_project_abilities(user)
    # All authenticated users can explore and read any project
    can :explore, Project
    can :read, Project

    # Project owners can manage their own projects
    can :manage, Project, user_id: user.id

    # Allow mentors to see projects they have active agreements with
    can :read, Project do |project|
      project.agreements.active.where(other_party_id: user.id).exists? ||
      project.agreements.completed.where(other_party_id: user.id).exists?
    end
  end

  def define_agreement_abilities(user)
    # Agreements
    can :read, Agreement do |agreement|
      is_party_to_agreement?(user, agreement)
    end

    can :create, Agreement do |agreement|
      true
    end

    can :edit, Agreement do |agreement|
      # Allow editing if user is the initiator of the latest counter offer
      agreement.latest_counter_offer&.initiator_id == user.id && !agreement.countered?
    end

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
      agreement.pending? && is_party_to_agreement?(user, agreement)
    end

    can :counter_offer, Agreement do |agreement|
      # Only the receiver can make a counter offer to a pending agreement
      last_initiator = agreement.counter_offers.order(created_at: :desc).first&.initiator_id
      can_make_counter_offer?(user, agreement, last_initiator)
    end

    can :complete, Agreement do |agreement|
      # Allow both entrepreneur and mentor to complete
      is_party_to_agreement?(user, agreement)
    end
  end

  def define_meeting_abilities(user)
    # Meetings
    can :manage, Meeting do |meeting|
      is_party_to_agreement?(user, meeting.agreement)
    end
  end

  def is_party_to_agreement?(user, agreement)
    agreement.initiator_id == user.id || agreement.other_party_id == user.id
  end

  def can_make_counter_offer?(user, agreement, last_initiator)
    (agreement.pending? || agreement.countered?) && (
      (agreement.other_party_id == user.id && agreement.initiator_id != user.id) ||
      (agreement.initiator_id == user.id && agreement.other_party_id != user.id)
    ) && ((last_initiator.present? && last_initiator != user.id) || agreement.initiator_id != user.id)
  end
end
