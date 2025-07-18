class ApplicationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  def initialize(attributes = {})
    @attributes = attributes
    super
  end

  def persisted?
    false
  end

  def to_key
    nil
  end

  def to_param
    nil
  end

  def model_name
    @model_name ||= ActiveModel::Name.new(self.class, nil, self.class.name.gsub("Form", ""))
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      perform_save
    end
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.full_messages.each do |message|
      errors.add(:base, message)
    end
    false
  end

  def save!
    if save
      true
    else
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

  private

  def perform_save
    raise NotImplementedError, "#{self.class} must implement #perform_save"
  end
end
