# frozen_string_literal: true

# Helper methods for SuggestedGotchas views
module SuggestedGotchasHelper
  # Returns an icon component for the trigger type
  def trigger_type_icon(trigger_type)
    icon_name = case trigger_type
    when SuggestedGotcha::RECURRING_ERROR
      :exclamation_circle
    when SuggestedGotcha::HIGH_FAILURE
      :arrow_trending_down
    when SuggestedGotcha::RETRY_SEQUENCE
      :arrow_path
    when SuggestedGotcha::LONG_DEBUGGING
      :clock
    when SuggestedGotcha::REPEATED_SEARCHES
      :magnifying_glass
    else
      :light_bulb
    end

    render Ui::IconComponent.new(name: icon_name, size: :sm)
  end

  # Returns a human-readable label for the trigger type
  def trigger_type_label(trigger_type)
    case trigger_type
    when SuggestedGotcha::RECURRING_ERROR
      "Recurring Errors"
    when SuggestedGotcha::HIGH_FAILURE
      "High Failure Rate"
    when SuggestedGotcha::RETRY_SEQUENCE
      "Retry Sequences"
    when SuggestedGotcha::LONG_DEBUGGING
      "Long Debugging Sessions"
    when SuggestedGotcha::REPEATED_SEARCHES
      "Repeated Searches"
    else
      trigger_type.to_s.titleize
    end
  end

  # Returns CSS classes for trigger type badge
  def trigger_type_badge_class(trigger_type)
    case trigger_type
    when SuggestedGotcha::RECURRING_ERROR
      "badge-error"
    when SuggestedGotcha::HIGH_FAILURE
      "badge-warning"
    when SuggestedGotcha::RETRY_SEQUENCE
      "badge-info"
    else
      "badge-neutral"
    end
  end
end
