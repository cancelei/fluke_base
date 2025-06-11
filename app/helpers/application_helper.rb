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

  def status_badge_class(status)
    case status.to_s.downcase
    when "completed", "accepted", "active"
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800"
    when "in_progress", "pending", "countered"
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800"
    when "rejected", "cancelled", "failed"
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800"
    when "not_started", "draft"
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800"
    else
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800"
    end
  end
  
  # Formats a GitHub repository URL for display and linking
  # @param repo_url [String] The repository URL (can be full URL or username/repo format)
  # @return [Hash] A hash with :display (formatted display text) and :url (full URL)
  def format_github_repo(repo_url)
    return nil if repo_url.blank?
    
    if repo_url.include?('github.com/')
      # Extract username/repo from full URL
      path = repo_url.gsub(%r{^https?://(www\.)?github\.com/}, '').gsub(/\.git$/, '')
      { display: path, url: "https://github.com/#{path}" }
    else
      # Assume it's in username/repo format
      { display: repo_url, url: "https://github.com/#{repo_url}" }
    end
  end
end
