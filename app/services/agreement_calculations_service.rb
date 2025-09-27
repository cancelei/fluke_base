class AgreementCalculationsService
  def initialize(agreement)
    @agreement = agreement
  end

  def total_cost
    # For equity-only agreements, there is no direct hourly cost component
    return 0 if @agreement.payment_type == Agreement::EQUITY
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
      base = "#{@agreement.hourly_rate}$/hour"
      if @agreement.weekly_hours.present?
        "#{base} for #{@agreement.weekly_hours}h/week"
      else
        base
      end
    when Agreement::EQUITY
      "#{@agreement.equity_percentage}% equity"
    when Agreement::HYBRID
      hourly = "#{@agreement.hourly_rate}$/hour ($#{@agreement.hourly_rate}/hour)"
      if @agreement.weekly_hours.present?
        "#{hourly}, #{@agreement.weekly_hours}h/week + #{@agreement.equity_percentage}% equity"
      else
        "#{hourly} + #{@agreement.equity_percentage}% equity"
      end
    end
  end

  def total_hours_logged(context_user = nil)
    # Aggregate time tracking across agreement milestones. When a context user
    # is provided, return only that user's completed hours. Otherwise, return
    # the total for all agreement participants.
    milestone_ids = Array(@agreement.milestone_ids).presence
    scope = @agreement.project.time_logs.completed
    scope = scope.where(milestone_id: milestone_ids) if milestone_ids

    if context_user
      scope.where(user_id: context_user.id).sum(:hours_spent).round(2)
    else
      participant_ids = @agreement.agreement_participants.pluck(:user_id)
      scope.where(user_id: participant_ids).sum(:hours_spent).round(2)
    end
  end

  def current_time_log
    # This method is used by the presenter, so we need to determine the context
    # For now, we'll show all participants' time logs, but this could be made more specific
    agreement_participant_ids = @agreement.agreement_participants.pluck(:user_id)
    @agreement.project.time_logs.where(user_id: agreement_participant_ids).in_progress.last
  end
end
