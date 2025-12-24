# frozen_string_literal: true

# Service for managing agreement status transitions
# Uses AASM state machine for validation, returns Result types for explicit success/failure handling
class AgreementStatusService < ApplicationService
  def initialize(agreement)
    @agreement = agreement
  end

  # @return [Dry::Monads::Result] Success(agreement) or Failure(error)
  def accept!
    return failure_result(:invalid_state, "Agreement must be pending to accept") unless @agreement.may_accept_agreement?

    @agreement.accept_agreement!
    Success(@agreement)
  rescue AASM::InvalidTransition => e
    failure_result(:invalid_state, e.message)
  end

  # @return [Dry::Monads::Result] Success(agreement) or Failure(error)
  def reject!
    return failure_result(:invalid_state, "Agreement must be pending to reject") unless @agreement.may_reject_agreement?

    @agreement.reject_agreement!
    Success(@agreement)
  rescue AASM::InvalidTransition => e
    failure_result(:invalid_state, e.message)
  end

  # @return [Dry::Monads::Result] Success(agreement) or Failure(error)
  def complete!
    return failure_result(:invalid_state, "Agreement must be active to complete") unless @agreement.may_complete_agreement?

    @agreement.complete_agreement!
    Success(@agreement)
  rescue AASM::InvalidTransition => e
    failure_result(:invalid_state, e.message)
  end

  # @return [Dry::Monads::Result] Success(agreement) or Failure(error)
  def cancel!
    return failure_result(:invalid_state, "Agreement must be pending to cancel") unless @agreement.may_cancel_agreement?

    @agreement.cancel_agreement!
    Success(@agreement)
  rescue AASM::InvalidTransition => e
    failure_result(:invalid_state, e.message)
  end

  # @return [Dry::Monads::Result] Success(counter_agreement) or Failure(error)
  def counter_offer!(counter_agreement)
    return failure_result(:invalid_state, "Agreement must be pending to counter") unless @agreement.may_counter_agreement?

    # Mark this agreement as countered using AASM
    @agreement.counter_agreement!

    # Link the new agreement to this one through participants
    counter_agreement.agreement_participants.each do |participant|
      participant.update!(counter_agreement_id: @agreement.id)
    end
    counter_agreement.status = Agreement::PENDING

    if counter_agreement.save
      Success(counter_agreement)
    else
      failure_result(:save_failed, counter_agreement.errors.full_messages.to_sentence, errors: counter_agreement.errors)
    end
  rescue AASM::InvalidTransition => e
    failure_result(:invalid_state, e.message)
  end

  def has_counter_offers? = @agreement.counter_offers.exists?
  def most_recent_counter_offer = @agreement.counter_offers.order(created_at: :desc).first
end
