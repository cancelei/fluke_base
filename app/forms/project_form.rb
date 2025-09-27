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

  validates :name, :description, :stage, presence: true
  validates :collaboration_type, inclusion: { in: [ "mentor", "co_founder", "both", nil ] }
  validates :repository_url, format: {
    with: /(^$|^https?:\/\/github\.com\/[^\/]+\/[^\/]+$|^[^\/\s]+\/[^\/\s]+$)/,
    message: "must be a valid GitHub repository URL or in the format username/repository"
  }, allow_blank: true

  def initialize(attributes = {})
    super
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
      [ Project::IDEA.humanize, Project::IDEA ],
      [ Project::PROTOTYPE.humanize, Project::PROTOTYPE ],
      [ Project::LAUNCHED.humanize, Project::LAUNCHED ],
      [ Project::SCALING.humanize, Project::SCALING ]
    ]
  end

  def collaboration_type_options
    [
      [ "Seeking Mentor", Project::SEEKING_MENTOR ],
      [ "Seeking Co-Founder", Project::SEEKING_COFOUNDER ],
      [ "Seeking Both", Project::SEEKING_BOTH ]
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

  private

  def perform_save
    @project = Project.new
    @is_update = false
    assign_attributes_to_project
    @project.save!
  end

  def assign_attributes_to_project
    @project.assign_attributes(
      name: name,
      description: description,
      stage: stage,
      category: category,
      current_stage: current_stage,
      target_market: target_market,
      funding_status: funding_status,
      team_size: team_size,
      collaboration_type: collaboration_type,
      repository_url: repository_url,
      project_link: project_link,
      public_fields: public_fields_array,
      user_id: user_id
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
    # Make essential fields public by default for better project discovery
    self.public_fields = Project::DEFAULT_PUBLIC_FIELDS if public_fields_array.blank?
  end
end
