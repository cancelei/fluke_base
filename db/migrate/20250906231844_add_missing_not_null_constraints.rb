class AddMissingNotNullConstraints < ActiveRecord::Migration[8.0]
  def up
    # Add NOT NULL constraints to columns that have presence validators in the models
    # We'll first check for any NULL values and provide default values where needed

    # Agreements table
    fix_nulls_and_add_constraint(:agreements, :agreement_type, "'Mentorship'")
    fix_nulls_and_add_constraint(:agreements, :status, "'draft'")
    fix_nulls_and_add_constraint(:agreements, :start_date, 'CURRENT_DATE')
    fix_nulls_and_add_constraint(:agreements, :end_date, 'CURRENT_DATE + INTERVAL \'30 days\'')
    fix_nulls_and_add_constraint(:agreements, :payment_type, "'hourly'")
    fix_nulls_and_add_constraint(:agreements, :weekly_hours, '10')
    fix_nulls_and_add_constraint(:agreements, :tasks, "'[]'")

    # Agreement participants table
    fix_nulls_and_add_constraint(:agreement_participants, :user_role, "'participant'")

    # GitHub branches table
    fix_nulls_and_add_constraint(:github_branches, :project_id, nil, true) # Skip if any nulls found
    fix_nulls_and_add_constraint(:github_branches, :user_id, nil, true) # Skip if any nulls found

    # GitHub logs table
    fix_nulls_and_add_constraint(:github_logs, :user_id, nil, true) # Skip if any nulls found
    fix_nulls_and_add_constraint(:github_logs, :commit_sha, nil, true) # Skip if any nulls found
    fix_nulls_and_add_constraint(:github_logs, :commit_date, 'CURRENT_TIMESTAMP')

    # Meetings table
    fix_nulls_and_add_constraint(:meetings, :title, "'Meeting'")
    fix_nulls_and_add_constraint(:meetings, :start_time, 'CURRENT_TIMESTAMP')
    fix_nulls_and_add_constraint(:meetings, :end_time, 'CURRENT_TIMESTAMP + INTERVAL \'1 hour\'')

    # Milestones table
    fix_nulls_and_add_constraint(:milestones, :title, "'Milestone'")
    fix_nulls_and_add_constraint(:milestones, :due_date, 'CURRENT_DATE + INTERVAL \'14 days\'')
    fix_nulls_and_add_constraint(:milestones, :status, "'pending'")

    # Notifications table
    fix_nulls_and_add_constraint(:notifications, :title, "'Notification'")
    fix_nulls_and_add_constraint(:notifications, :message, "'You have a new notification'")

    # Projects table
    fix_nulls_and_add_constraint(:projects, :name, "'Untitled Project'")
    fix_nulls_and_add_constraint(:projects, :description, "'No description provided'")
    fix_nulls_and_add_constraint(:projects, :stage, "'idea'")

    # Roles table
    fix_nulls_and_add_constraint(:roles, :name, "'user'")

    # SolidQueue claimed executions table
    fix_nulls_and_add_constraint(:solid_queue_claimed_executions, :process_id, nil, true) # Skip if any nulls found

    # Time logs table
    fix_nulls_and_add_constraint(:time_logs, :project_id, nil, true) # Skip if any nulls found

    # Users table
    fix_nulls_and_add_constraint(:users, :first_name, "'User'")
    fix_nulls_and_add_constraint(:users, :last_name, "'Name'")
  end

  def down
    # Remove NOT NULL constraints
    remove_not_null_constraint(:agreements, :agreement_type)
    remove_not_null_constraint(:agreements, :status)
    remove_not_null_constraint(:agreements, :start_date)
    remove_not_null_constraint(:agreements, :end_date)
    remove_not_null_constraint(:agreements, :payment_type)
    remove_not_null_constraint(:agreements, :weekly_hours)
    remove_not_null_constraint(:agreements, :tasks)

    remove_not_null_constraint(:agreement_participants, :user_role)

    remove_not_null_constraint(:github_branches, :project_id)
    remove_not_null_constraint(:github_branches, :user_id)

    remove_not_null_constraint(:github_logs, :user_id)
    remove_not_null_constraint(:github_logs, :commit_sha)
    remove_not_null_constraint(:github_logs, :commit_date)

    remove_not_null_constraint(:meetings, :title)
    remove_not_null_constraint(:meetings, :start_time)
    remove_not_null_constraint(:meetings, :end_time)

    remove_not_null_constraint(:milestones, :title)
    remove_not_null_constraint(:milestones, :due_date)
    remove_not_null_constraint(:milestones, :status)

    remove_not_null_constraint(:notifications, :title)
    remove_not_null_constraint(:notifications, :message)

    remove_not_null_constraint(:projects, :name)
    remove_not_null_constraint(:projects, :description)
    remove_not_null_constraint(:projects, :stage)

    remove_not_null_constraint(:roles, :name)

    remove_not_null_constraint(:solid_queue_claimed_executions, :process_id)

    remove_not_null_constraint(:time_logs, :project_id)

    remove_not_null_constraint(:users, :first_name)
    remove_not_null_constraint(:users, :last_name)
  end

  private

  def fix_nulls_and_add_constraint(table, column, default_value, skip_if_nulls = false)
    # Check if there are any NULL values
    null_count = execute("SELECT COUNT(*) FROM #{table} WHERE #{column} IS NULL").first['count'].to_i

    if null_count > 0
      if skip_if_nulls
        puts "Skipping NOT NULL constraint on #{table}.#{column} because there are #{null_count} NULL values"
        return
      end

      # Update NULL values with default value
      if default_value.nil?
        puts "Cannot add NOT NULL constraint to #{table}.#{column} because there are #{null_count} NULL values and no default value provided"
        return
      end

      execute("UPDATE #{table} SET #{column} = #{default_value} WHERE #{column} IS NULL")
    end

    # Add NOT NULL constraint
    change_column_null table, column, false
  end

  def remove_not_null_constraint(table, column)
    change_column_null table, column, true
  end
end
