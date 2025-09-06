class AddMissingForeignKeyConstraints < ActiveRecord::Migration[8.0]
  def up
    # Clean up inconsistent data before adding foreign keys
    cleanup_inconsistent_data

    # Add foreign key constraints identified by active_record_doctor
    # We'll add them directly without the validate: false option since we've cleaned up the data
    add_foreign_key :github_branch_logs, :github_branches, column: :github_branch_id, on_delete: :cascade
    add_foreign_key :github_branch_logs, :github_logs, column: :github_log_id, on_delete: :cascade

    # Check if users.selected_project_id references projects.id
    if column_exists?(:users, :selected_project_id) && table_exists?(:projects)
      # Nullify any invalid references first
      execute <<-SQL
        UPDATE users SET selected_project_id = NULL#{' '}
        WHERE selected_project_id IS NOT NULL AND#{' '}
              NOT EXISTS (SELECT 1 FROM projects WHERE projects.id = users.selected_project_id)
      SQL
      add_foreign_key :users, :projects, column: :selected_project_id, on_delete: :nullify
    end

    # SolidQueue foreign keys - only add if tables exist
    if table_exists?(:solid_queue_claimed_executions) && table_exists?(:solid_queue_processes)
      # Clean up any inconsistent references
      execute <<-SQL
        DELETE FROM solid_queue_claimed_executions#{' '}
        WHERE process_id IS NOT NULL AND#{' '}
              NOT EXISTS (SELECT 1 FROM solid_queue_processes WHERE solid_queue_processes.id = solid_queue_claimed_executions.process_id)
      SQL
      add_foreign_key :solid_queue_claimed_executions, :solid_queue_processes, column: :process_id, on_delete: :cascade
    end

    if table_exists?(:solid_queue_processes) && column_exists?(:solid_queue_processes, :supervisor_id)
      # Nullify any invalid references
      execute <<-SQL
        UPDATE solid_queue_processes SET supervisor_id = NULL#{' '}
        WHERE supervisor_id IS NOT NULL AND#{' '}
              NOT EXISTS (SELECT 1 FROM solid_queue_processes p2 WHERE p2.id = solid_queue_processes.supervisor_id)
      SQL
      add_foreign_key :solid_queue_processes, :solid_queue_processes, column: :supervisor_id, on_delete: :nullify
    end

    if table_exists?(:solid_queue_jobs) && table_exists?(:active_jobs) && column_exists?(:solid_queue_jobs, :active_job_id)
      # This is likely a polymorphic association, so we'll skip it for now
      # add_foreign_key :solid_queue_jobs, :active_jobs, column: :active_job_id, on_delete: :cascade
    end
  end

  def down
    # Remove foreign key constraints
    remove_foreign_key :github_branch_logs, column: :github_branch_id if foreign_key_exists?(:github_branch_logs, :github_branches)
    remove_foreign_key :github_branch_logs, column: :github_log_id if foreign_key_exists?(:github_branch_logs, :github_logs)

    if column_exists?(:users, :selected_project_id) && table_exists?(:projects)
      remove_foreign_key :users, column: :selected_project_id if foreign_key_exists?(:users, :projects)
    end

    if table_exists?(:solid_queue_claimed_executions) && table_exists?(:solid_queue_processes)
      remove_foreign_key :solid_queue_claimed_executions, column: :process_id if foreign_key_exists?(:solid_queue_claimed_executions, :solid_queue_processes)
    end

    if table_exists?(:solid_queue_processes) && column_exists?(:solid_queue_processes, :supervisor_id)
      remove_foreign_key :solid_queue_processes, column: :supervisor_id if foreign_key_exists?(:solid_queue_processes, :solid_queue_processes)
    end
  end

  private

  def cleanup_inconsistent_data
    # Clean up github_branch_logs with invalid github_branch_id references
    execute <<-SQL
      DELETE FROM github_branch_logs#{' '}
      WHERE github_branch_id IS NOT NULL AND#{' '}
            NOT EXISTS (SELECT 1 FROM github_branches WHERE github_branches.id = github_branch_logs.github_branch_id)
    SQL

    # Clean up github_branch_logs with invalid github_log_id references
    execute <<-SQL
      DELETE FROM github_branch_logs#{' '}
      WHERE github_log_id IS NOT NULL AND#{' '}
            NOT EXISTS (SELECT 1 FROM github_logs WHERE github_logs.id = github_branch_logs.github_log_id)
    SQL
  end

  def foreign_key_exists?(from_table, to_table)
    foreign_keys = connection.foreign_keys(from_table)
    foreign_keys.any? { |fk| fk.to_table.to_s == to_table.to_s }
  end
end
