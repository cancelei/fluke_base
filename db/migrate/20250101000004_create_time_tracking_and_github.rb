class CreateTimeTrackingAndGithub < ActiveRecord::Migration[8.0]
  def change
    # Only create tables if they don't already exist (for new setups)
    return if table_exists?(:time_logs)

    # Time logs table
    create_table :time_logs do |t|
      t.references :milestone, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.text :description
      t.decimal :hours_spent, precision: 10, scale: 2, default: 0.0
      t.string :status, default: "in_progress"
      t.boolean :manual_entry, default: false
      t.timestamps null: false
    end

    # Time log indexes and constraints
    add_index :time_logs, :milestone_id
    add_index :time_logs, :user_id
    add_index :time_logs, :project_id
    add_index :time_logs, :started_at, comment: "Improves time-based queries and reporting"
    add_index :time_logs, :status, comment: "Improves filtering by active/completed time logs"
    add_index :time_logs, [ :project_id, :milestone_id ]
    add_index :time_logs, [ :project_id, :user_id ], comment: "Composite index for user-project time logs"

    add_check_constraint :time_logs,
      "status IN ('in_progress', 'completed', 'paused')",
      name: "time_logs_status_check"
    add_check_constraint :time_logs,
      "hours_spent >= 0",
      name: "time_logs_hours_check"

    # GitHub branches table
    create_table :github_branches do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :branch_name
      t.timestamps null: false
    end

    # GitHub branch indexes
    add_index :github_branches, :user_id
    add_index :github_branches, [ :project_id, :branch_name, :user_id ],
      unique: true, name: "idx_on_project_id_branch_name_user_id_fcdce7d2d8"

    # GitHub logs table
    create_table :github_logs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :agreement, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :commit_sha, null: false
      t.text :commit_message
      t.integer :lines_added
      t.integer :lines_removed
      t.datetime :commit_date, null: false
      t.string :commit_url
      t.jsonb :changed_files, array: true, default: []
      t.string :unregistered_user_name
      t.timestamps null: false
    end

    # GitHub log indexes
    add_index :github_logs, :project_id
    add_index :github_logs, :agreement_id
    add_index :github_logs, :user_id
    add_index :github_logs, :commit_sha, unique: true
    add_index :github_logs, :commit_date, comment: "Improves time-based queries for commit history"
    add_index :github_logs, [ :project_id, :commit_date ], comment: "Composite index for project commit timeline"
    add_index :github_logs, [ :user_id, :commit_date ], comment: "Composite index for user commit activity"

    # GitHub branch logs junction table
    create_table :github_branch_logs do |t|
      t.references :github_branch, null: false, foreign_key: { on_delete: :cascade }
      t.references :github_log, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps null: false
    end

    # GitHub branch log indexes
    add_index :github_branch_logs, :github_log_id
    add_index :github_branch_logs, [ :github_branch_id, :github_log_id ],
      unique: true, name: "index_github_branch_logs_on_github_branch_id_and_github_log_id"
  end
end
