# frozen_string_literal: true

# Service for managing agreement status transitions
# Returns Result types for explicit success/failure handling
class AgreementStatusService < ApplicationService
  def initialize(agreement)
    @agreement = agreement
  end

  # @return [Dry::Monads::Result] Success(agreement) or Failure(error)
  def accept!
    return failure_result(:invalid_state, "Agreement must be pending to accept") unless @agreement.pending?

    if @agreement.update(status: Agreement::ACCEPTED)
      Success(@agreement)
    else
      failure_result(:update_failed, @agreement.errors.full_messages.to_sentence, errors: @agreement.errors)
    end
  end

  # @return [Dry::Monads::Result] Success(agreement) or Failure(error)
  def reject!
    return failure_result(:invalid_state, "Agreement must be pending to reject") unless @agreement.pending?

    if @agreement.update(status: Agreement::REJECTED)
      Success(@agreement)
    else
      failure_result(:update_failed, @agreement.errors.full_messages.to_sentence, errors: @agreement.errors)
    end
  end

  # @return [Dry::Monads::Result] Success(agreement) or Failure(error)
  def complete!
    return failure_result(:invalid_state, "Agreement must be active to complete") unless @agreement.active?

    if @agreement.update(status: Agreement::COMPLETED)
      Success(@agreement)
    else
      failure_result(:update_failed, @agreement.errors.full_messages.to_sentence, errors: @agreement.errors)
    end
  end

  # @return [Dry::Monads::Result] Success(agreement) or Failure(error)
  def cancel!
    return failure_result(:invalid_state, "Agreement must be pending to cancel") unless @agreement.pending?

    if @agreement.update(status: Agreement::CANCELLED)
      Success(@agreement)
    else
      failure_result(:update_failed, @agreement.errors.full_messages.to_sentence, errors: @agreement.errors)
    end
  end

  # @return [Dry::Monads::Result] Success(counter_agreement) or Failure(error)
  def counter_offer!(counter_agreement)
    return failure_result(:invalid_state, "Agreement must be pending to counter") unless @agreement.pending?

    # Mark this agreement as countered
    @agreement.update(status: Agreement::COUNTERED)

    # Link the new agreement to this one
    # Set the counter agreement relationship through participants
    counter_agreement.agreement_participants.each do |participant|
      participant.update!(counter_agreement_id: @agreement.id)
    end
    counter_agreement.status = Agreement::PENDING

    if counter_agreement.save
      Success(counter_agreement)
    else
      failure_result(:save_failed, counter_agreement.errors.full_messages.to_sentence, errors: counter_agreement.errors)
    end
  end

  # Returns the latest counter offer for this agreement
  def latest_counter_offer
    # If this is an original agreement, find counter offers made to it
    if @agreement.counter_to_id.nil?
      Agreement.where(id: @agreement.id).order(created_at: :desc).first
    else
      # If this is a counter offer, find newer counter offers made to the original agreement
      original_agreement = Agreement.find(@agreement.counter_to_id)
      original_agreement.counter_offers.order(created_at: :desc).first
    end
  end

  def has_counter_offers?
    @agreement.counter_offers.exists?
  end

  def most_recent_counter_offer
    @agreement.counter_offers.order(created_at: :desc).first
  end
end
