Rails.application.config.after_initialize do
  next if ENV["SKIP_DB_INITIALIZER"] == "true" || ARGV.include?("assets:precompile")

  if ActiveRecord::Base.connected? && ActiveRecord::Base.connection.table_exists?("roles")
    if ActiveRecord::Migrator.current_version.positive?
      Role.ensure_default_roles_exist
    end
  end
end
