# Ensure default roles exist in the database
Rails.application.config.after_initialize do
  if ActiveRecord::Base.connection.table_exists?("roles")
    # Only run if we're not in a database migration
    if ActiveRecord::Migrator.current_version.positive?
      Role.ensure_default_roles_exist
    end
  end
end
