# frozen_string_literal: true

# == Schema Information
#
# Table name: environment_configs
#
#  id             :bigint           not null, primary key
#  description    :text
#  environment    :string           not null
#  last_synced_at :datetime
#  metadata       :jsonb
#  sync_count     :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  project_id     :bigint           not null
#
# Indexes
#
#  index_environment_configs_on_project_id                  (project_id)
#  index_environment_configs_on_project_id_and_environment  (project_id,environment) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
class EnvironmentConfig < ApplicationRecord
  belongs_to :project

  # Validations
  validates :environment, presence: true,
                          uniqueness: { scope: :project_id },
                          inclusion: { in: EnvironmentVariable::ENVIRONMENTS }

  # Get variables for this environment
  def variables
    project.environment_variables.for_environment(environment)
  end

  # Count of variables
  def variables_count
    variables.count
  end

  # Get required variables for this environment
  def required_variables
    variables.required
  end

  # Get secret variables for this environment
  def secret_variables
    variables.secrets
  end

  # Record a sync event
  def record_sync!
    update!(
      last_synced_at: Time.current,
      sync_count: sync_count + 1
    )
  end

  # Check if never synced
  def never_synced?
    last_synced_at.nil?
  end

  # Get time since last sync
  def time_since_sync
    return nil if never_synced?
    Time.current - last_synced_at
  end
end
