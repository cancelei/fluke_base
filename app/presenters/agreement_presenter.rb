class AgreementPresenter < ApplicationPresenter
  include Rails.application.routes.url_helpers

  def status_badge
    status_class = case status
    when Agreement::ACCEPTED
      "badge-success"
    when Agreement::PENDING
      "badge-warning"
    when Agreement::COMPLETED
      "badge-info"
    when Agreement::REJECTED
      "badge-error"
    when Agreement::CANCELLED
      "badge-ghost"
    when Agreement::COUNTERED
      "badge-warning"
    else
      "badge-ghost"
    end

    "<span class=\"badge #{status_class}\">#{status}</span>".html_safe
  end

  def agreement_type_badge
    type_class = case agreement_type
    when Agreement::MENTORSHIP
      "badge-success"
    when Agreement::CO_FOUNDER
      "badge-secondary"
    else
      "badge-ghost"
    end

    "<span class=\"badge #{type_class}\">#{agreement_type}</span>".html_safe
  end

  def payment_type_badge
    type_class = case payment_type
    when Agreement::HOURLY
      "badge-info"
    when Agreement::EQUITY
      "badge-warning"
    when Agreement::HYBRID
      "badge-secondary"
    else
      "badge-ghost"
    end

    "<span class=\"badge #{type_class}\">#{payment_type}</span>".html_safe
  end

  def formatted_payment_details
    calculations_service = AgreementCalculationsService.new(object)
    calculations_service.payment_details
  end

  def duration_display
    return "Duration not specified" unless start_date.present? && end_date.present?

    days = (end_date - start_date).to_i
    weeks = duration_in_weeks

    if weeks < 4
      "#{days} days"
    elsif weeks < 12
      "#{weeks} weeks"
    else
      months = (weeks / 4.0).round(1)
      "#{months} months"
    end
  end

  def total_commitment_display
    return "Commitment not specified" unless weekly_hours.present?

    weeks = duration_in_weeks
    total_hours = weekly_hours * weeks

    "#{weekly_hours} hours/week for #{duration_display} (#{total_hours} total hours)"
  end

  def progress_summary(current_user = nil)
    if active? || completed?
      hours_logged = total_hours_logged(current_user)

      if completed?
        # For completed agreements, show final summary
        expected_total_hours = weekly_hours * duration_in_weeks
        if expected_total_hours > 0
          percentage = (hours_logged / expected_total_hours * 100).round
          "#{hours_logged} total hours logged (#{percentage}% of contracted #{expected_total_hours}h)"
        else
          "#{hours_logged} total hours logged"
        end
      else
        # For active agreements, show progress to date
        expected_hours = weekly_hours * weeks_elapsed
        if expected_hours > 0
          percentage = (hours_logged / expected_hours * 100).round
          "#{hours_logged} hours logged (#{percentage}% of expected)"
        else
          "#{hours_logged} hours logged"
        end
      end
    else
      "Agreement not active"
    end
  end

  def financial_summary
    cost = calculate_total_cost
    return "Cost not calculated" unless cost.present?

    if active?
      hours_logged = total_hours_logged
      earned = hours_logged * hourly_rate if hourly_rate.present?

      if earned
        remaining = cost - earned
        "Total: #{number_to_currency(cost)} | Earned: #{number_to_currency(earned)} | Remaining: #{number_to_currency(remaining)}"
      else
        "Total cost: #{number_to_currency(cost)}"
      end
    else
      "Estimated total: #{number_to_currency(cost)}"
    end
  end

  def milestone_progress
    return "No milestones selected" if milestone_ids.blank?

    total = selected_milestones.count
    completed = selected_milestones.where(status: Milestone::COMPLETED).count

    percentage = total > 0 ? (completed.to_f / total * 100).round : 0

    "#{completed}/#{total} milestones completed (#{percentage}%)"
  end

  def time_remaining
    return "No end date set" unless end_date.present?

    if completed?
      # For completed agreements, show completion summary
      actual_duration = (updated_at.to_date - start_date).to_i
      planned_duration = (end_date - start_date).to_i

      if actual_duration <= planned_duration
        days_early = planned_duration - actual_duration
        if days_early > 0
          "Completed #{days_early} days early"
        else
          "Completed on time"
        end
      else
        days_late = actual_duration - planned_duration
        "Completed #{days_late} days late"
      end
    elsif active?
      # For active agreements, show remaining time
      days_remaining = (end_date - Date.current).to_i

      if days_remaining < 0
        "Overdue by #{days_remaining.abs} days"
      elsif days_remaining == 0
        "Due today"
      elsif days_remaining < 7
        "#{days_remaining} days remaining"
      else
        weeks_remaining = (days_remaining / 7.0).round(1)
        "#{weeks_remaining} weeks remaining"
      end
    else
      "Agreement not active"
    end
  end

  def parties_display
    initiator_name = UserPresenter.new(initiator).display_name
    other_party_name = UserPresenter.new(other_party).display_name

    "#{initiator_name} ↔ #{other_party_name}"
  end

  def project_link
    h.link_to project.name, h.project_path(project),
            class: "link link-primary font-medium",
            data: { turbo_frame: "_top" }
  end

  def created_timeframe
    if created_at > 1.week.ago
      "Created #{time_ago_in_words(created_at)} ago"
    else
      "Created #{created_at.strftime('%B %d, %Y')}"
    end
  end

  def created_timeframe_simple
    time_ago_in_words(created_at)
  end

  def counter_offer_info
    # Temporarily simplified to avoid controller access issues
    "Counter offer history temporarily disabled"
  end

  def meetings_summary
    return "No meetings scheduled" unless meetings.exists?

    upcoming = meetings.upcoming.count
    past = meetings.past.count

    parts = []
    parts << "#{upcoming} upcoming" if upcoming > 0
    parts << "#{past} completed" if past > 0

    parts.join(", ")
  end

  # Turn-based negotiation methods - delegate to model's turn-based logic
  # These use accept_or_counter_turn_id to determine whose turn it is to act
  def can_be_accepted_by?(user)
    object.user_can_accept?(user)
  end

  def can_be_rejected_by?(user)
    object.user_can_reject?(user)
  end

  def can_be_cancelled_by?(user)
    # Any participant can cancel a pending agreement
    pending? && agreement_participants.exists?(user_id: user.id)
  end

  def can_be_completed_by?(user)
    # Any participant can mark an active agreement as completed
    active? && agreement_participants.exists?(user_id: user.id)
  end

  def can_make_counter_offer?(user)
    object.user_can_make_counter_offer?(user)
  end

  def kpi_metrics_for_owner(current_user = nil)
    return {} unless active? || completed?

    {
      hours_performance: hours_performance_kpi(current_user),
      timeline_performance: timeline_performance_kpi,
      milestone_performance: milestone_performance_kpi,
      cost_efficiency: cost_efficiency_kpi(current_user),
      completion_status: completion_status_kpi
    }
  end

  def hours_performance_kpi(current_user = nil)
    hours_logged = total_hours_logged(current_user)
    expected_hours = if completed?
      weekly_hours * duration_in_weeks
    else
      weekly_hours * weeks_elapsed
    end

    return { status: "no_data", message: "No time tracked yet" } if expected_hours == 0

    performance_ratio = (hours_logged / expected_hours.to_f * 100).round

    status = if performance_ratio >= 95
      "excellent"
    elsif performance_ratio >= 80
      "good"
    elsif performance_ratio >= 60
      "fair"
    else
      "poor"
    end

    {
      status:,
      hours_logged:,
      expected_hours:,
      performance_ratio:,
      message: "#{hours_logged}/#{expected_hours}h logged (#{performance_ratio}%)"
    }
  end

  def timeline_performance_kpi
    return { status: "pending", message: "Agreement not started" } unless start_date <= Date.current

    if completed?
      actual_duration = (updated_at.to_date - start_date).to_i
      planned_duration = (end_date - start_date).to_i

      if actual_duration <= planned_duration
        days_early = planned_duration - actual_duration
        status = days_early > 7 ? "excellent" : "good"
        message = days_early > 0 ? "Completed #{days_early} days early" : "Completed on time"
      else
        days_late = actual_duration - planned_duration
        status = days_late > 14 ? "poor" : "fair"
        message = "Completed #{days_late} days late"
      end
    else
      days_remaining = (end_date - Date.current).to_i
      if days_remaining > 0
        status = "on_track"
        message = "#{days_remaining} days remaining"
      else
        days_overdue = days_remaining.abs
        status = days_overdue > 14 ? "poor" : "fair"
        message = "#{days_overdue} days overdue"
      end
    end

    { status:, message: }
  end

  def milestone_performance_kpi
    return { status: "no_milestones", message: "No milestones defined" } if milestone_ids.blank?

    total = selected_milestones.count
    completed_count = selected_milestones.where(status: Milestone::COMPLETED).count

    completion_rate = (completed_count.to_f / total * 100).round

    status = if completion_rate == 100
      "excellent"
    elsif completion_rate >= 75
      "good"
    elsif completion_rate >= 50
      "fair"
    else
      "poor"
    end

    {
      status:,
      completed: completed_count,
      total:,
      completion_rate:,
      message: "#{completed_count}/#{total} milestones (#{completion_rate}%)"
    }
  end

  def cost_efficiency_kpi(current_user = nil)
    return { status: "no_data", message: "No cost tracking" } unless hourly_rate.present?

    hours_logged = total_hours_logged(current_user)
    return { status: "no_data", message: "No hours logged yet" } if hours_logged == 0

    actual_cost = hours_logged * hourly_rate

    if completed?
      planned_cost = calculate_total_cost
      efficiency = (planned_cost / actual_cost * 100).round

      status = if efficiency >= 100
        "excellent"
      elsif efficiency >= 90
        "good"
      elsif efficiency >= 80
        "fair"
      else
        "poor"
      end

      message = "#{number_to_currency(actual_cost)} spent (#{efficiency}% efficient)"
    else
      expected_cost_to_date = weekly_hours * weeks_elapsed * hourly_rate
      if expected_cost_to_date > 0
        efficiency = (expected_cost_to_date / actual_cost * 100).round
        status = efficiency >= 95 ? "good" : "fair"
        message = "#{number_to_currency(actual_cost)} spent vs #{number_to_currency(expected_cost_to_date)} expected"
      else
        status = "tracking"
        message = "#{number_to_currency(actual_cost)} spent"
      end
    end

    { status:, message:, actual_cost: }
  end

  def completion_status_kpi
    case status
    when Agreement::COMPLETED
      days_to_complete = (updated_at.to_date - start_date).to_i
      planned_days = (end_date - start_date).to_i

      if days_to_complete <= planned_days
        { status: "excellent", message: "Successfully completed", icon: "check-circle" }
      else
        { status: "good", message: "Completed (delayed)", icon: "check-circle" }
      end
    when Agreement::ACCEPTED
      days_remaining = (end_date - Date.current).to_i
      if days_remaining > 7
        { status: "on_track", message: "In progress", icon: "clock" }
      elsif days_remaining >= 0
        { status: "fair", message: "Due soon", icon: "exclamation-triangle" }
      else
        { status: "poor", message: "Overdue", icon: "exclamation-circle" }
      end
    else
      { status: "pending", message: status.humanize, icon: "clock" }
    end
  end

  private

  def weeks_elapsed
    return 0 unless start_date.present? && start_date <= Date.current

    end_comparison = [Date.current, end_date].compact.min
    ((end_comparison - start_date) / 7.0).ceil
  end

  def current_user_id
    # For now, return nil to avoid controller access issues
    # This will cause the presenter to always show full names instead of "you"
    nil
  end
end
