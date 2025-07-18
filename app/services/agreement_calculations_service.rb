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

  def total_hours_logged
    @agreement.time_logs.completed.sum(:hours_spent).round(2)
  end

  def current_time_log
    @agreement.time_logs.in_progress.last
  end
end
