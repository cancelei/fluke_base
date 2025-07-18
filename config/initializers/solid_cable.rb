# Explicitly configure SolidCable for different environments
# This ensures the correct database connection settings are loaded

Rails.application.config.to_prepare do
  if defined?(SolidCable)
    # Load cable configuration from config/cable.yml
    cable_config = Rails.application.config_for(:cable)

    # Only apply if using solid_cable adapter
    if cable_config[:adapter] == "solid_cable"
      # Make sure the database connection is properly configured
      db_config = cable_config[:connects_to]&.deep_symbolize_keys

      if db_config.present?
        SolidCable::Record.connects_to(database: db_config)
      else
        # Fallback to a standard database connection if connects_to isn't specified
        SolidCable::Record.connects_to(database: { writing: :cable || cable_config[:database] })
      end
    end
  end
end
