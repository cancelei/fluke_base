class ProjectForm < ApplicationForm
  attribute :name, :string
  attribute :description, :string
  attribute :stage, :string
  attribute :category, :string
  attribute :current_stage, :string
  attribute :target_market, :string
  attribute :funding_status, :string
  attribute :team_size, :integer
  attribute :collaboration_type, :string
  attribute :repository_url, :string
  attribute :public_fields, :string
  attribute :user_id, :integer

  validates :name, :description, :stage, presence: true
  validates :collaboration_type, inclusion: { in: [ "mentor", "co_founder", "both", nil ] }
  validates :repository_url, format: {
    with: /(^$|^https?:\/\/github\.com\/[^\/]+\/[^\/]+$|^[^\/\s]+\/[^\/\s]+$)/,
    message: "must be a valid GitHub repository URL or in the format username/repository"
  }, allow_blank: true
  validates :team_size, numericality: { greater_than: 0 }, allow_blank: true

  def initialize(attributes = {})
    super
    self.public_fields = parse_public_fields(public_fields)
    set_defaults
  end

  def public_fields_array
    @public_fields_array ||= Array(public_fields)
  end

  def public_fields=(value)
    @public_fields_array = nil
    super(parse_public_fields(value))
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
      public_fields: public_fields_array,
      user_id: user_id
    )
  end

  def parse_public_fields(value)
    case value
    when String
      value.split(",").map(&:strip).reject(&:blank?)
    when Array
      value.reject(&:blank?)
    else
      []
    end
  end

  def set_defaults
    self.stage ||= Project::IDEA
    self.current_stage ||= stage.humanize if stage.present?
    self.collaboration_type ||= Project::SEEKING_MENTOR
    self.public_fields ||= []
  end
end
