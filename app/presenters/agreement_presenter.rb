class AgreementPresenter < ApplicationPresenter
  include Rails.application.routes.url_helpers

  def status_badge
    status_class = case status
    when Agreement::ACCEPTED
      "bg-green-100 text-green-800"
    when Agreement::PENDING
      "bg-yellow-100 text-yellow-800"
    when Agreement::COMPLETED
      "bg-blue-100 text-blue-800"
    when Agreement::REJECTED
      "bg-red-100 text-red-800"
    when Agreement::CANCELLED
      "bg-gray-100 text-gray-800"
    when Agreement::COUNTERED
      "bg-orange-100 text-orange-800"
    else
      "bg-gray-100 text-gray-800"
    end

    "<span class=\"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{status_class}\">#{status}</span>".html_safe
  end

  def agreement_type_badge
    type_class = case agreement_type
    when Agreement::MENTORSHIP
      "bg-green-100 text-green-800"
    when Agreement::CO_FOUNDER
      "bg-purple-100 text-purple-800"
    else
      "bg-gray-100 text-gray-800"
    end

    "<span class=\"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{type_class}\">#{agreement_type}</span>".html_safe
  end

  def payment_type_badge
    type_class = case payment_type
    when Agreement::HOURLY
      "bg-blue-100 text-blue-800"
    when Agreement::EQUITY
      "bg-yellow-100 text-yellow-800"
    when Agreement::HYBRID
      "bg-purple-100 text-purple-800"
    else
      "bg-gray-100 text-gray-800"
    end

    "<span class=\"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{type_class}\">#{payment_type}</span>".html_safe
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

  def progress_summary
    if active?
      hours_logged = total_hours_logged
      expected_hours = weekly_hours * weeks_elapsed

      if expected_hours > 0
        percentage = (hours_logged / expected_hours * 100).round
        "#{hours_logged} hours logged (#{percentage}% of expected)"
      else
        "#{hours_logged} hours logged"
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
    return "Agreement not active" unless active?
    return "No end date set" unless end_date.present?

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
  end

  def parties_display
    initiator_name = UserPresenter.new(initiator).display_name
    other_party_name = UserPresenter.new(other_party).display_name

    "#{initiator_name} ↔ #{other_party_name}"
  end

  def project_link
    h.link_to project.name, h.project_path(project),
            class: "text-blue-600 hover:text-blue-800 font-medium",
            data: { turbo_frame: "_top" }
  end

  def created_timeframe
    if created_at > 1.week.ago
      "Created #{time_ago_in_words(created_at)} ago"
    else
      "Created #{created_at.strftime('%B %d, %Y')}"
    end
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

  def can_be_accepted_by?(user)
    pending? && agreement_participants.exists?(user_id: user.id, is_initiator: false)
  end

  def can_be_rejected_by?(user)
    pending? && agreement_participants.exists?(user_id: user.id, is_initiator: false)
  end

  def can_be_cancelled_by?(user)
    pending? && agreement_participants.exists?(user_id: user.id)
  end

  def can_be_completed_by?(user)
    active? && agreement_participants.exists?(user_id: user.id)
  end

  def can_make_counter_offer?(user)
    pending? && agreement_participants.exists?(user_id: user.id, is_initiator: false)
  end

  private

  def weeks_elapsed
    return 0 unless start_date.present? && start_date <= Date.current

    end_comparison = [ Date.current, end_date ].compact.min
    ((end_comparison - start_date) / 7.0).ceil
  end

  def current_user_id
    # For now, return nil to avoid controller access issues
    # This will cause the presenter to always show full names instead of "you"
    nil
  end
end
