require "json"

class ProjectForm < ApplicationForm
  # Make this form object use 'project' as the param key for Rails forms
  def self.model_name
    ActiveModel::Name.new(self, nil, "Project")
  end
  attribute :name, :string
  attribute :description, :string
  attribute :stage, :string
  attribute :category, :string
  attribute :current_stage, :string
  attribute :target_market, :string
  attribute :funding_status, :string
  attribute :team_size, :string
  attribute :collaboration_type, :string
  attribute :repository_url, :string
  attribute :project_link, :string
  attribute :public_fields, default: -> { [] }
  attribute :user_id, :integer
  attribute :stealth_mode, :boolean, default: false
  attribute :stealth_name, :string
  attribute :stealth_description, :string
  attribute :stealth_category, :string

  validates :name, :description, :stage, presence: true
  validates :collaboration_type, inclusion: { in: ["mentor", "co_founder", "both", nil] }
  validates :repository_url, format: {
    with: /\A([a-zA-Z0-9._-]+\/[a-zA-Z0-9._-]+)?\z/,
    message: "must be a valid GitHub repository (e.g., username/repository)"
  }, allow_blank: true

  def initialize(attributes = {})
    super
    normalize_repository_url
    self.public_fields = parse_public_fields(public_fields)
    set_defaults
  end

  def public_fields_array
    @public_fields_array ||= parse_public_fields(public_fields)
  end

  def public_fields=(value)
    parsed = parse_public_fields(value)
    @public_fields_array = parsed
    super(parsed)
  end

  def stage_options
    [
      [Project::IDEA.humanize, Project::IDEA],
      [Project::PROTOTYPE.humanize, Project::PROTOTYPE],
      [Project::LAUNCHED.humanize, Project::LAUNCHED],
      [Project::SCALING.humanize, Project::SCALING]
    ]
  end

  def collaboration_type_options
    [
      ["Seeking Mentor", Project::SEEKING_MENTOR],
      ["Seeking Co-Founder", Project::SEEKING_COFOUNDER],
      ["Seeking Both", Project::SEEKING_BOTH]
    ]
  end

  def public_field_options
    Project::PUBLIC_FIELD_OPTIONS
  end

  def field_public?(field_name)
    public_fields_array.include?(field_name.to_s)
  end

  def update_project(project)
    @project = project
    @is_update = true
    assign_attributes_to_project
    @project.save!
  end

  def project
    @project
  end

  def stealth_mode?
    stealth_mode == true
  end

  private

  def perform_save
    @project = Project.new
    @is_update = false
    assign_attributes_to_project
    @project.save!
  end

  def assign_attributes_to_project
    @project.assign_attributes(
      name:,
      description:,
      stage:,
      category:,
      current_stage:,
      target_market:,
      funding_status:,
      team_size:,
      collaboration_type:,
      repository_url:,
      project_link:,
      public_fields: public_fields_array,
      user_id:,
      stealth_mode:,
      stealth_name:,
      stealth_description:,
      stealth_category:
    )
  end

  def parse_public_fields(value)
    array = case value
    when String
              parse_string_public_fields(value)
    when Array
              value
    when nil
              []
    else
              Array.wrap(value)
    end

    Array.wrap(array).map { |item| item.to_s.strip }.reject(&:blank?)
  end

  def parse_string_public_fields(value)
    return [] if value.blank?

    parsed = parse_json_array(value)
    return parsed if parsed

    value.split(",")
  end

  def parse_json_array(value)
    parsed = JSON.parse(value)
    parsed.is_a?(Array) ? parsed : nil
  rescue JSON::ParserError
    nil
  end

  def set_defaults
    self.stage ||= Project::IDEA
    self.current_stage ||= stage.humanize if stage.present?
    self.collaboration_type ||= Project::SEEKING_MENTOR

    # Handle stealth mode defaults
    if stealth_mode?
      apply_stealth_defaults
    else
      # Make essential fields public by default for better project discovery
      self.public_fields = Project::DEFAULT_PUBLIC_FIELDS if public_fields_array.blank?
    end
  end

  def apply_stealth_defaults
    # Stealth projects default to completely private
    self.public_fields = [] if public_fields_array.blank?

    # Apply stealth-specific pre-filled defaults only if fields are blank
    if name.blank?
      self.name = stealth_name.presence || generate_stealth_name
    end

    if description.blank?
      self.description = stealth_description.presence || "Early-stage venture in development. Details available after connection."
    end

    if category.blank?
      self.category = stealth_category.presence || "Technology"
    end
  end

  def generate_stealth_name
    "Stealth Startup #{SecureRandom.hex(2).upcase}"
  end

  def normalize_repository_url
    return if repository_url.blank?

    url = repository_url.to_s.strip

    # Remove query parameters and fragments
    url = url.split("?").first.to_s
    url = url.split("#").first.to_s

    if url.match?(%r{github\.com/}i)
      # Extract path after github.com/
      path = url.gsub(%r{^https?://(www\.)?github\.com/}i, "")
      # Remove .git suffix, trailing slashes, and extra paths (tree/main, issues, etc.)
      path = path.gsub(/\.git$/i, "").gsub(%r{/+$}, "")
      # Take only first two segments (owner/repo)
      segments = path.split("/").first(2)
      self.repository_url = segments.length == 2 ? segments.join("/") : nil
    else
      # Already in owner/repo format - just clean it
      self.repository_url = url.gsub(/\.git$/i, "").gsub(%r{/+$}, "")
    end
  end
end
