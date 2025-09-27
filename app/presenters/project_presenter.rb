class ProjectPresenter < ApplicationPresenter
  def display_name(current_user = nil)
    if current_user && (user_id == current_user.id || visible_to_user?(:name, current_user))
      name
    elsif stealth? && !visibility_service.stealth_visible_to_user?(current_user)
      stealth_display_name
    else
      "Project ##{id}"
    end
  end

  def display_description(current_user = nil, options = {})
    if current_user && visible_to_user?(:description, current_user)
      desc = description
      desc = truncate(desc, length: options[:length] || 150) if options[:truncate]
      simple_format(desc)
    elsif stealth? && !visibility_service.stealth_visible_to_user?(current_user)
      desc = stealth_display_description
      desc = truncate(desc, length: options[:length] || 150) if options[:truncate]
      simple_format(desc)
    else
      "<p class=\"text-gray-500 italic\">Available after agreement acceptance</p>".html_safe
    end
  end

  def stage_badge
    return "" unless stage.present?

    stage_class = case stage
    when Project::IDEA
      "bg-blue-100 text-blue-800"
    when Project::PROTOTYPE
      "bg-yellow-100 text-yellow-800"
    when Project::LAUNCHED
      "bg-green-100 text-green-800"
    when Project::SCALING
      "bg-purple-100 text-purple-800"
    else
      "bg-gray-100 text-gray-800"
    end

    "<span class=\"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{stage_class}\">#{stage.humanize}</span>".html_safe
  end

  def collaboration_badges
    return "" unless collaboration_type.present?

    badges = []

    if seeking_mentor?
      badges << "<span class=\"inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800\">Seeking Mentor</span>"
    end

    if seeking_cofounder?
      badges << "<span class=\"inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800\">Seeking Co-Founder</span>"
    end

    badges.join(" ").html_safe
  end

  def stealth_badge
    return "" unless stealth?
    "<span class=\"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800\">🔒 Stealth</span>".html_safe
  end

  def progress_bar
    percentage = progress_percentage
    return "" if percentage.zero?

    color_class = case percentage
    when 0..25
      "bg-red-500"
    when 26..50
      "bg-yellow-500"
    when 51..75
      "bg-blue-500"
    else
      "bg-green-500"
    end

    <<~HTML.html_safe
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div class="#{color_class} h-2 rounded-full transition-all duration-300" style="width: #{percentage}%"></div>
      </div>
      <span class="text-sm text-gray-600 mt-1">#{percentage}% complete</span>
    HTML
  end

  def milestones_summary
    total = milestones.count
    completed = milestones.where(status: Milestone::COMPLETED).count
    in_progress = milestones.where(status: Milestone::IN_PROGRESS).count

    parts = []
    parts << "#{completed} completed" if completed > 0
    parts << "#{in_progress} in progress" if in_progress > 0
    parts << "#{total - completed - in_progress} not started" if total - completed - in_progress > 0

    return "No milestones set" if total.zero?

    "#{total} milestones: #{parts.join(', ')}"
  end



  def team_size_display
    return "Team size not specified" unless team_size.present?

    case team_size
    when 1
      "Solo founder"
    when 2..5
      "Small team (#{team_size} people)"
    when 6..15
      "Medium team (#{team_size} people)"
    else
      "Large team (#{team_size}+ people)"
    end
  end

  def funding_status_badge
    return "" unless funding_status.present?

    status_class = case funding_status.downcase
    when "bootstrapped", "self-funded"
      "bg-green-100 text-green-800"
    when "seed", "angel"
      "bg-yellow-100 text-yellow-800"
    when "series a", "series b", "series c"
      "bg-blue-100 text-blue-800"
    when "pre-revenue", "looking for funding"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end

    "<span class=\"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{status_class}\">#{funding_status}</span>".html_safe
  end

  def created_timeframe
    if created_at > 1.week.ago
      "#{time_ago_in_words(created_at)} ago"
    else
      "Created #{created_at.strftime('%B %Y')}"
    end
  end

  def collaboration_status
    active_agreements = agreements.where(status: Agreement::ACCEPTED).count
    pending_agreements = agreements.where(status: Agreement::PENDING).count

    parts = []
    parts << "#{active_agreements} active" if active_agreements > 0
    parts << "#{pending_agreements} pending" if pending_agreements > 0

    return "No active collaborations" if parts.empty?

    "#{parts.join(', ')} collaboration#{'s' if active_agreements + pending_agreements > 1}"
  end

  def owner_display
    UserPresenter.new(user).display_name
  end





  private

  def visibility_service
    @visibility_service ||= ProjectVisibilityService.new(self)
  end

  def format_github_repo
    return nil if repository_url.blank?

    if repository_url.include?("github.com/")
      path = repository_url.gsub(%r{^https?://(www\.)?github\.com/}, "").gsub(/\.git$/, "")
      { display: path, url: "https://github.com/#{path}" }
    else
      { display: repository_url, url: "https://github.com/#{repository_url}" }
    end
  end
end
