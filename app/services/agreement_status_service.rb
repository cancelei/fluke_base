class AgreementStatusService
  def initialize(agreement)
    @agreement = agreement
  end

  def accept!
    return false unless @agreement.pending?
    @agreement.update(status: Agreement::ACCEPTED)
  end

  def reject!
    return false unless @agreement.pending?
    @agreement.update(status: Agreement::REJECTED)
  end

  def complete!
    return false unless @agreement.active?
    @agreement.update(status: Agreement::COMPLETED)
  end

  def cancel!
    return false unless @agreement.pending?
    @agreement.update(status: Agreement::CANCELLED)
  end

  def counter_offer!(counter_agreement)
    return false unless @agreement.pending?

    # Mark this agreement as countered
    @agreement.update(status: Agreement::COUNTERED)

    # Link the new agreement to this one
    counter_agreement.counter_to_id = @agreement.id
    counter_agreement.status = Agreement::PENDING

    counter_agreement.save
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
