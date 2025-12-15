# frozen_string_literal: true

class MeetingPolicy < ApplicationPolicy
  def index?
    return false unless signed_in?

    # User must be able to view the agreement to see its meetings
    agreement = record.respond_to?(:agreement) ? record.agreement : nil
    return false unless agreement

    AgreementPolicy.new(user, agreement).view_meetings?
  end

  def show?
    return true if admin?
    return false unless signed_in?

    # User can view meeting if they're a participant in the agreement
    agreement_participant?
  end

  def create?
    return false unless signed_in?
    return true if admin?

    # Participants of an active agreement can create meetings
    return false unless record&.agreement

    agreement_participant? && record.agreement.active?
  end

  def new?
    create?
  end

  def update?
    return true if admin?
    return false unless signed_in?

    # Participants can update meetings for their agreements
    agreement_participant?
  end

  def edit?
    update?
  end

  def destroy?
    return true if admin?
    return false unless signed_in?

    # Participants can delete meetings for their agreements
    agreement_participant?
  end

  class Scope < Scope
    def resolve
      if user.nil?
        # Unauthenticated users can't see any meetings
        scope.none
      elsif user.admin?
        # Admins see all meetings
        scope.all
      else
        # Users see meetings for agreements they're participants in
        scope.joins(agreement: :agreement_participants)
             .where(agreement_participants: { user_id: user.id })
             .distinct
      end
    end
  end

  protected

  def agreement_participant?
    return false unless record&.agreement

    record.agreement.agreement_participants.exists?(user_id: user.id)
  end
end
