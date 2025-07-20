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

  # Enhanced navbar helper methods for modern design

  def enhanced_navbar_link(text, path, icon_path, options = {})
    current_condition = options[:current_condition] || -> { current_page?(path) }
    is_current = current_condition.call
    badge_count = options[:badge_count]

    base_classes = "group relative inline-flex items-center space-x-2 rounded-xl px-3 py-2 text-sm font-medium transition-all duration-200"
    css_classes = is_current ? "#{base_classes} bg-gradient-to-r from-blue-100 to-purple-100 text-blue-700" : "#{base_classes} text-gray-700 hover:bg-gradient-to-r hover:from-gray-50 hover:to-blue-50 hover:text-gray-900"
    icon_color = is_current ? "text-blue-500" : "text-gray-400 group-hover:text-blue-500"

    link_content = capture do
      concat tag.div(class: "flex items-center space-x-2") {
        concat tag.svg(class: "w-4 h-4 #{icon_color} transition-colors", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") {
          tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: strip_tags(icon_path))
        }
        concat tag.span(strip_tags(text))
      }
      concat tag.span(strip_tags(badge_count.to_s), class: "absolute -top-1 -right-1 inline-flex items-center justify-center w-5 h-5 text-xs font-medium text-white bg-red-500 rounded-full") if badge_count.present? && badge_count > 0
    end

    link_to link_content, path, class: css_classes, **options.except(:current_condition, :badge_count)
  end

  def enhanced_dropdown_link(text, path, icon_path, options = {})
    link_content = capture do
      concat tag.svg(class: "w-4 h-4 text-gray-400 group-hover:text-blue-500 transition-colors", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") {
        tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: strip_tags(icon_path))
      }
      concat tag.span(strip_tags(text))
    end

    link_to link_content, path, class: "group flex items-center space-x-3 rounded-xl px-4 py-3 text-sm font-medium text-gray-700 hover:bg-gradient-to-r hover:from-gray-50 hover:to-blue-50 hover:text-gray-900 transition-all duration-200", **options
  end

  def enhanced_mobile_link(text, path, icon_path, options = {})
    badge_count = options[:badge_count]

    link_content = capture do
      concat tag.svg(class: "w-5 h-5 text-gray-400 group-hover:text-blue-500 transition-colors", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") {
        tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: strip_tags(icon_path))
      }
      concat tag.span(strip_tags(text))
    end

    base_content = link_to link_content, path, class: "group flex items-center space-x-3 rounded-xl px-3 py-3 text-sm font-medium text-gray-700 hover:bg-gradient-to-r hover:from-gray-50 hover:to-blue-50 hover:text-gray-900 transition-all duration-200", **options.except(:badge_count)

    if badge_count.present? && badge_count > 0
      tag.div(class: "relative") do
        concat base_content
        concat tag.span(strip_tags(badge_count.to_s), class: "absolute -top-1 -right-1 inline-flex items-center justify-center w-5 h-5 text-xs font-medium text-white bg-red-500 rounded-full")
      end
    else
      base_content
    end
  end

  def smooth_scroll_link(text, anchor)
    link_to text, anchor, class: "inline-flex items-center rounded-xl px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gradient-to-r hover:from-gray-50 hover:to-blue-50 hover:text-gray-900 transition-all duration-200", data: { behavior: "smooth" }
  end

  def mobile_smooth_scroll_link(text, anchor)
    link_to text, anchor, class: "block rounded-xl px-3 py-3 text-base font-medium text-gray-700 hover:bg-gradient-to-r hover:from-gray-50 hover:to-blue-50 hover:text-gray-900 transition-all duration-200", data: { behavior: "smooth" }
  end
end
