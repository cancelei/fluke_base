class UserPresenter < ApplicationPresenter
  def display_name
    full_name.presence || "User ##{id}"
  end



  def avatar_image_tag(options = {})
    size = options.delete(:size) || 40
    css_class = options.delete(:class) || "rounded-full"

    if avatar.attached?
      image_tag(avatar, alt: initials, class: css_class, style: "width: #{size}px; height: #{size}px;")
    else
      # Return SVG directly for initials avatar
      avatar_url.html_safe
    end
  end

  def badges
    "<span class=\"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800\">Community Person</span>".html_safe
  end

  def formatted_bio
    return "No bio provided" unless bio.present?

    simple_format(bio)
  end



  def hourly_rate_display
    return "Rate not specified" unless hourly_rate.present?

    "$#{hourly_rate}/hour"
  end







  def member_since
    "Member since #{created_at.strftime('%B %Y')}"
  end

  def projects_count
    pluralize(projects.count, "project")
  end

  def agreements_count
    pluralize(all_agreements.count, "agreement")
  end

  def completion_rate
    total = all_agreements.count
    return "No agreements yet" if total.zero?

    completed = all_agreements.where(status: Agreement::COMPLETED).count
    percentage = (completed.to_f / total * 100).round
    "#{percentage}% completion rate"
  end
end
