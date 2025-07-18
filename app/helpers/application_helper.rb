module ApplicationHelper
  include UiHelper

  def page_entries_info(collection = nil)
    collection ||= @projects

    if collection&.total_count.to_i > 0
      start_number = (collection.current_page - 1) * collection.limit_value + 1
      end_number = [ collection.current_page * collection.limit_value, collection.total_count ].min
      "#{start_number} to #{end_number} of #{collection.total_count} entries"
    else
      "No entries found"
    end
  end

  # Formats a GitHub repository URL for display and linking
  # @param repo_url [String] The repository URL (can be full URL or username/repo format)
  # @return [Hash] A hash with :display (formatted display text) and :url (full URL)
  def format_github_repo(repo_url)
    return nil if repo_url.blank?

    if repo_url.include?("github.com/")
      # Extract username/repo from full URL
      path = repo_url.gsub(%r{^https?://(www\.)?github\.com/}, "").gsub(/\.git$/, "")
      { display: path, url: "https://github.com/#{path}" }
    else
      # Assume it's in username/repo format
      { display: repo_url, url: "https://github.com/#{repo_url}" }
    end
  end

  def time_ago_in_words_or_date(time)
    return "N/A" unless time.present?

    if time > 1.week.ago
      "#{time_ago_in_words(time)} ago"
    else
      time.strftime("%b %d, %Y")
    end
  end

  def truncate_html(html, options = {})
    length = options[:length] || 100
    truncate(strip_tags(html), length: length)
  end

  def page_header(title, subtitle = nil, actions = nil, options = {})
    render "shared/page_header", title: title, subtitle: subtitle, actions: actions, options: options
  end

  def search_form(url, options = {}, &block)
    render partial: "shared/search_form", locals: { url: url, **options, block: block }
  end

  def navbar_link(text, path, options = {})
    current_condition = options[:current_condition] || -> { current_page?(path) }
    is_current = current_condition.call

    css_classes = [
      "inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium",
      is_current ? "border-indigo-500 text-gray-900" : "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
    ].join(" ")

    link_to text, path, class: css_classes, **options.except(:current_condition)
  end
end
