# frozen_string_literal: true

# Helper methods for Team Board views
module TeamBoardHelper
  # Render a badge for task status
  def render_status_badge(status)
    case status
    when "pending"
      content_tag(:span, "Pending", class: "badge badge-warning gap-1")
    when "in_progress"
      content_tag(:span, "In Progress", class: "badge badge-info gap-1")
    when "blocked"
      content_tag(:span, "Blocked", class: "badge badge-error gap-1")
    when "completed"
      content_tag(:span, "Completed", class: "badge badge-success gap-1")
    else
      content_tag(:span, status.humanize, class: "badge badge-ghost gap-1")
    end
  end

  # Render a small badge for priority (used in task cards)
  def render_priority_badge(priority)
    case priority
    when "urgent"
      content_tag(:span, class: "badge badge-error badge-xs gap-1") do
        concat(render(Ui::IconComponent.new(name: :fire, size: :xs)))
        concat("Urgent")
      end
    when "high"
      content_tag(:span, "High", class: "badge badge-warning badge-xs")
    when "normal"
      # No badge for normal priority to reduce visual noise
      nil
    when "low"
      content_tag(:span, "Low", class: "badge badge-ghost badge-xs")
    end
  end

  # Render a full priority badge (used in task detail)
  def render_priority_badge_full(priority)
    case priority
    when "urgent"
      content_tag(:span, "Urgent Priority", class: "badge badge-error gap-1")
    when "high"
      content_tag(:span, "High Priority", class: "badge badge-warning gap-1")
    when "normal"
      content_tag(:span, "Normal Priority", class: "badge badge-ghost gap-1")
    when "low"
      content_tag(:span, "Low Priority", class: "badge badge-ghost badge-outline gap-1")
    end
  end

  # Get the next logical status for a task
  def next_status(current_status)
    case current_status
    when "pending" then "in_progress"
    when "in_progress" then "completed"
    when "blocked" then "in_progress"
    else "pending"
    end
  end

  # Get CSS classes for a status column
  def status_column_classes(status)
    base = "bg-base-200 rounded-lg p-4"
    "#{base} status-column-#{status}"
  end

  # Get icon name for a status
  def status_icon(status)
    case status
    when "pending" then :clock
    when "in_progress" then :play
    when "blocked" then :exclamation_triangle
    when "completed" then :check_circle
    else :question_mark_circle
    end
  end

  # Get color class for a status
  def status_color_class(status)
    case status
    when "pending" then "text-warning"
    when "in_progress" then "text-info"
    when "blocked" then "text-error"
    when "completed" then "text-success"
    else "text-base-content"
    end
  end
end
