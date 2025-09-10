class AgreementCalculationsService
  def initialize(agreement)
    @agreement = agreement
  end

  def total_cost
    return nil unless @agreement.hourly_rate.present? && @agreement.weekly_hours.present?
    return 0 if @agreement.hourly_rate == 0

    weeks = duration_in_weeks
    @agreement.hourly_rate * @agreement.weekly_hours * weeks
  end

  def duration_in_weeks
    return 0 unless @agreement.start_date.present? && @agreement.end_date.present?
    ((@agreement.end_date - @agreement.start_date).to_f / 7).ceil
  end

  def payment_details
    case @agreement.payment_type
    when Agreement::HOURLY
      "#{@agreement.hourly_rate}$/hour"
    when Agreement::EQUITY
      "#{@agreement.equity_percentage}% equity"
    when Agreement::HYBRID
      "#{@agreement.hourly_rate}$/hour + #{@agreement.equity_percentage}% equity"
    end
  end

  def total_hours_logged(context_user = nil)
    # Context-aware time tracking:
    # - For project owners: show only the other party's hours (the work done for them)
    # - For agreement participants: show all agreement participants' hours
    # - Default (no context): show other party's hours (most common use case)

    if context_user&.id == @agreement.project.user_id
      # Project owner viewing - show only other party's time logs
      other_party = @agreement.other_party
      return 0 unless other_party
      @agreement.project.time_logs.where(user_id: other_party.id).completed.sum(:hours_spent).round(2)
    else
      # Agreement participant or default - show work done by non-project-owner participants
      # This is typically the mentor/co-founder's work
      other_party = @agreement.other_party
      return 0 unless other_party
      @agreement.project.time_logs.where(user_id: other_party.id).completed.sum(:hours_spent).round(2)
    end
  end

  def current_time_log
    # This method is used by the presenter, so we need to determine the context
    # For now, we'll show all participants' time logs, but this could be made more specific
    agreement_participant_ids = @agreement.agreement_participants.pluck(:user_id)
    @agreement.project.time_logs.where(user_id: agreement_participant_ids).in_progress.last
  end
end
