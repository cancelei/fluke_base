module ApplicationHelper
  def page_entries_info
    if @projects.total_count > 0
      start_number = (@projects.current_page - 1) * @projects.limit_value + 1
      end_number = [ @projects.current_page * @projects.limit_value, @projects.total_count ].min
      "#{start_number} to #{end_number} of #{@projects.total_count} projects"
    else
      "No projects found"
    end
  end

  def sanitize_url(url)
    return nil unless url.present?
    # Only allow http and https protocols
    sanitized = url.strip
    return nil unless sanitized.match?(%r{\Ahttps?://})
    sanitized
  end
end
