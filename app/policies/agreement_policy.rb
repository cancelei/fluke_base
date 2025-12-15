# frozen_string_literal: true

class AgreementPolicy < ApplicationPolicy
  def index?
    signed_in?
  end

  def show?
    return true if admin?
    return false unless signed_in?

    # Participants can view the agreement
    participant?(user)
  end

  def create?
    return false unless signed_in?

    # User must have access to the project
    project = record.respond_to?(:project) ? record.project : nil
    return false unless project

    ProjectPolicy.new(user, project).show?
  end

  def new?
    create?
  end

  def update?
    return true if admin?
    return false unless signed_in?

    # Only initiator can update a pending agreement
    record.pending? && record.initiator_id == user.id
  end

  def edit?
    update?
  end

  def destroy?
    return true if admin?
    return false unless signed_in?

    # Only initiator can delete a pending agreement
    record.pending? && record.initiator_id == user.id
  end

  # Agreement action permissions

  def accept?
    return false unless signed_in?
    return false unless participant?(user)

    record.user_can_accept?(user)
  end

  def reject?
    return false unless signed_in?
    return false unless participant?(user)

    record.user_can_reject?(user)
  end

  def counter?
    return false unless signed_in?
    return false unless participant?(user)

    record.user_can_make_counter_offer?(user)
  end

  def cancel?
    return true if admin?
    return false unless signed_in?
    return false unless participant?(user)

    # Participants can cancel active agreements
    record.active? || record.pending?
  end

  def complete?
    return true if admin?
    return false unless signed_in?

    # Only the initiator can mark an agreement as complete
    record.active? && record.initiator_id == user.id
  end

  # View permissions

  def view_full_details?
    return true if admin?
    return false unless signed_in?

    participant?(user)
  end

  def view_counter_offers?
    return true if admin?
    return false unless signed_in?

    participant?(user)
  end

  def view_meetings?
    return true if admin?
    return false unless signed_in?

    participant?(user) && record.active?
  end

  def view_time_logs?
    return true if admin?
    return false unless signed_in?

    participant?(user) && (record.active? || record.completed?)
  end

  def view_github_logs?
    return true if admin?
    return false unless signed_in?

    participant?(user) && (record.active? || record.completed?)
  end

  # Lazy-loaded section permissions (for Turbo Frame loading)

  def meetings_section?
    view_meetings?
  end

  def github_section?
    view_github_logs?
  end

  def counter_offers_section?
    view_counter_offers?
  end

  class Scope < Scope
    def resolve
      if user.nil?
        # Unauthenticated users can't see any agreements
        scope.none
      elsif user.admin?
        # Admins see all agreements
        scope.all
      else
        # Users see agreements they're participants in
        scope.joins(:agreement_participants)
             .where(agreement_participants: { user_id: user.id })
             .distinct
      end
    end
  end

  protected

  def participant?(user_to_check)
    return false unless user_to_check
    record.agreement_participants.exists?(user_id: user_to_check.id)
  end
end
