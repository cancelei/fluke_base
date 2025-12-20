module ApplicationHelper
  include UiHelper

  # Presenter helper exposed to views/specs
  def present(object, with: nil)
    controller.present(object, with:)
  end

  def page_entries_info(collection = nil)
    collection ||= @projects

    if collection&.total_count.to_i > 0
      start_number = (collection.current_page - 1) * collection.limit_value + 1
      end_number = [collection.current_page * collection.limit_value, collection.total_count].min
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
    truncate(strip_tags(html), length:)
  end

  def page_header(title, subtitle = nil, actions = nil, options = {})
    render "shared/page_header", title:, subtitle:, actions:, options:
  end

  def search_form(url, options = {}, &block)
    render partial: "shared/search_form", locals: { url:, **options, block: }
  end

  # DaisyUI navbar link - uses menu-item styling
  def navbar_link(text, path, options = {})
    current_condition = options[:current_condition] || -> { current_page?(path) }
    is_current = current_condition.call

    # DaisyUI menu styling
    css_classes = is_current ? "btn btn-ghost btn-active" : "btn btn-ghost"

    link_to text, path, class: css_classes, **options.except(:current_condition)
  end

  # Enhanced navbar helper methods using DaisyUI

  def enhanced_navbar_link(text, path, icon_path, options = {})
    current_condition = options[:current_condition] || -> { current_page?(path) }
    is_current = current_condition.call
    badge_count = options[:badge_count]

    # DaisyUI button styling
    css_classes = is_current ? "btn btn-ghost btn-active gap-2" : "btn btn-ghost gap-2"
    icon_color = is_current ? "text-primary" : "text-base-content/70"

    link_content = capture do
      concat tag.div(class: "flex items-center gap-2") {
        concat tag.svg(class: "w-4 h-4 #{icon_color}", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") {
          tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: strip_tags(icon_path))
        }
        concat tag.span(strip_tags(text))
      }
      concat tag.span(strip_tags(badge_count.to_s), class: "badge badge-error badge-sm") if badge_count.present? && badge_count > 0
    end

    link_to link_content, path, class: css_classes, **options.except(:current_condition, :badge_count)
  end

  # DaisyUI dropdown menu link
  def enhanced_dropdown_link(text, path, icon_path, options = {})
    link_content = capture do
      concat tag.svg(class: "w-4 h-4 text-base-content/70", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") {
        tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: strip_tags(icon_path))
      }
      concat tag.span(strip_tags(text))
    end

    link_to link_content, path, class: "flex items-center gap-3", **options
  end

  # DaisyUI mobile menu link
  def enhanced_mobile_link(text, path, icon_path, options = {})
    badge_count = options[:badge_count]

    link_content = capture do
      concat tag.svg(class: "w-5 h-5 text-base-content/70", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") {
        tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: strip_tags(icon_path))
      }
      concat tag.span(strip_tags(text))
      concat tag.span(strip_tags(badge_count.to_s), class: "badge badge-error badge-sm") if badge_count.present? && badge_count > 0
    end

    link_to link_content, path, class: "flex items-center gap-3", **options.except(:badge_count)
  end

  # DaisyUI smooth scroll link
  def smooth_scroll_link(text, anchor, mobile: false)
    destination = (controller_name == "home" && action_name == "index") ? anchor : "#{root_path}#{anchor}"
    css_class = mobile ? "flex items-center gap-2" : "btn btn-ghost btn-sm"
    link_to text, destination, class: css_class, data: { behavior: "smooth" }
  end

  # Returns the current theme for the user
  # Priority: session > user preference > default
  def current_theme
    return session[:theme_preference] if session[:theme_preference].present?
    return current_user.theme_preference if user_signed_in? && current_user.theme_preference.present?

    User::DEFAULT_THEME
  end

  # Returns all available themes organized by category with actual DaisyUI v5 colors
  # Colors: [base-100, base-200, base-content, primary, secondary, accent, neutral]
  def available_themes
    # Theme definitions - uses DaisyUI's built-in theme names
    # The theme preview cards use data-theme attribute for proper CSS variable isolation
    {
      light: [
        { id: "light", name: "Light" },
        { id: "nord", name: "Nord" },
        { id: "cupcake", name: "Cupcake" },
        { id: "emerald", name: "Emerald" },
        { id: "corporate", name: "Corporate" }
      ],
      dark: [
        { id: "dark", name: "Dark" },
        { id: "night", name: "Night" },
        { id: "dracula", name: "Dracula" },
        { id: "forest", name: "Forest" },
        { id: "business", name: "Business" }
      ]
    }
  end

  # Check if a theme is a dark theme
  def dark_theme?(theme_id)
    available_themes[:dark].any? { |t| t[:id] == theme_id }
  end
end
