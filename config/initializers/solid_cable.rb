# Configure SolidCable to use primary database for single database setup

Rails.application.config.to_prepare do
  if defined?(SolidCable)
    # Load cable configuration from config/cable.yml
    cable_config = Rails.application.config_for(:cable)

    # Only apply if using solid_cable adapter
    if cable_config[:adapter] == "solid_cable"
      # Use primary database for single database setup
      SolidCable::Record.connects_to(database: { writing: :primary })
    end
  end
end
