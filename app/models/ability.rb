# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the user here
    return unless user.present?

    # Note: Admin functionality removed with role system

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
      project.agreements.active.joins(:agreement_participants).where(agreement_participants: { user_id: user.id }).exists? ||
      project.agreements.completed.joins(:agreement_participants).where(agreement_participants: { user_id: user.id }).exists?
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
      # Allow editing if user is the initiator and agreement is pending
      agreement.pending? && agreement.initiator&.id == user.id
    end

    can :has_counter_offer, Agreement do |agreement|
      agreement.counter_offers.joins(:agreement_participants).exists?(agreement_participants: { user_id: agreement.initiator&.id })
    end

    can :accept, Agreement do |agreement|
      # Use turn-based system: only the user whose turn it is can accept
      agreement.user_can_accept?(user)
    end

    can :reject, Agreement do |agreement|
      # Use turn-based system: only the user whose turn it is can reject
      agreement.user_can_reject?(user)
    end

    can :cancel, Agreement do |agreement|
      # Either party can cancel while pending
      agreement.pending? && is_party_to_agreement?(user, agreement)
    end

    can :counter_offer, Agreement do |agreement|
      # Use turn-based system: only the user whose turn it is can make a counter offer
      agreement.user_can_make_counter_offer?(user)
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
    agreement.agreement_participants.exists?(user_id: user.id)
  end
end
