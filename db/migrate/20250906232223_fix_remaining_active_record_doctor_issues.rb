class FixRemainingActiveRecordDoctorIssues < ActiveRecord::Migration[8.0]
  def change
    # Check if the index exists using a more reliable method
    index_exists = connection.execute(<<-SQL).any?
      SELECT 1 FROM pg_indexes#{' '}
      WHERE tablename = 'github_logs' AND indexname = 'index_github_logs_on_commit_sha'
    SQL

    # Add unique index on github_logs(commit_sha) if it doesn't exist
    # This ensures each commit is only recorded once
    unless index_exists
      begin
        add_index :github_logs, :commit_sha, unique: true, name: 'index_github_logs_on_commit_sha'
      rescue ActiveRecord::StatementInvalid => e
        # If the index already exists, just log the error and continue
        puts "Index already exists: #{e.message}"
      end
    end

    # Add foreign key on meetings.google_calendar_event_id if the referenced table exists
    # Since this might be an external reference, we need to check if the table exists
    if column_exists?(:meetings, :google_calendar_event_id) &&
       table_exists?(:google_calendar_events) &&
       !foreign_key_exists?(:meetings, :google_calendar_events)
      add_foreign_key :meetings, :google_calendar_events,
                      column: :google_calendar_event_id,
                      on_delete: :nullify
    end

    # Add foreign key on solid_queue_jobs.active_job_id if the referenced table exists
    # This is likely a polymorphic association, so we'll only add it if the table exists
    if column_exists?(:solid_queue_jobs, :active_job_id) &&
       table_exists?(:active_jobs) &&
       !foreign_key_exists?(:solid_queue_jobs, :active_jobs)
      add_foreign_key :solid_queue_jobs, :active_jobs,
                      column: :active_job_id,
                      on_delete: :cascade
    end
  end

  private

  def foreign_key_exists?(from_table, to_table)
    foreign_keys = connection.foreign_keys(from_table)
    foreign_keys.any? { |fk| fk.to_table.to_s == to_table.to_s }
  end
end
