class MarkConsolidatedMigrationsComplete < ActiveRecord::Migration[8.0]
  def up
    # This migration tells Rails that our consolidated migrations have already been "run"
    # for existing databases, so they won't be executed again

    if table_exists?(:users) && table_exists?(:projects) && table_exists?(:agreements)
      say "Existing database detected. Marking consolidated migrations as complete..."

      # Mark all our consolidated migrations as already run
      consolidated_versions = [
        '20250101000001', # create_core_users_and_roles
        '20250101000002', # create_projects_and_collaboration
        '20250101000003', # create_communication_system
        '20250101000004', # create_time_tracking_and_github
        '20250101000005', # create_active_storage_tables
        '20250101000006', # create_solid_queue_tables
        '20250101000007', # create_solid_cable_tables
        '20250101000008'  # add_user_project_references
      ]

      consolidated_versions.each do |version|
        unless ActiveRecord::Base.connection.select_value("SELECT version FROM schema_migrations WHERE version = '#{version}'")
          ActiveRecord::Base.connection.insert("INSERT INTO schema_migrations (version) VALUES ('#{version}')")
          say "Marked migration #{version} as complete"
        end
      end

      say "All consolidated migrations marked as complete for existing database"
    else
      say "New database detected - consolidated migrations will run normally"
    end
  end

  def down
    # Remove the consolidated migration markers
    consolidated_versions = [
      '20250101000001', '20250101000002', '20250101000003', '20250101000004',
      '20250101000005', '20250101000006', '20250101000007', '20250101000008'
    ]

    consolidated_versions.each do |version|
      ActiveRecord::Base.connection.delete("DELETE FROM schema_migrations WHERE version = '#{version}'")
    end
  end
end
