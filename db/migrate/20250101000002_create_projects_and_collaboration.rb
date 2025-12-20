class CreateProjectsAndCollaboration < ActiveRecord::Migration[8.0]
  def change
    # Only create tables if they don't already exist (for new setups)
    return if table_exists?(:projects)

    # Projects table
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :stage, null: false
      t.references :user, null: false, foreign_key: true

      # Project details
      t.string :category
      t.string :current_stage
      t.text :target_market
      t.string :funding_status
      t.string :team_size
      t.string :collaboration_type
      t.string :public_fields, array: true, default: [], null: false
      t.string :repository_url
      t.string :project_link

      t.timestamps null: false
    end

    # Project indexes and constraints
    add_index :projects, :user_id
    add_index :projects, :stage, comment: "Improves filtering by project stage"
    add_index :projects, :collaboration_type, comment: "Improves filtering by seeking mentor/co-founder"
    add_index :projects, :created_at, comment: "Improves ordering by project creation"

    add_check_constraint :projects,
      "stage IN ('idea', 'prototype', 'launched', 'scaling')",
      name: "projects_stage_check"

    # Milestones table
    create_table :milestones do |t|
      t.string :title, null: false
      t.text :description
      t.date :due_date, null: false
      t.string :status, null: false
      t.references :project, null: false, foreign_key: true
      t.timestamps null: false
    end

    # Milestone indexes and constraints
    add_index :milestones, :project_id
    add_index :milestones, :due_date, comment: "Improves due date queries and sorting"
    add_index :milestones, :status, comment: "Improves filtering by milestone status"
    add_index :milestones, [:project_id, :due_date], comment: "Composite index for project milestone timeline"
    add_index :milestones, [:project_id, :status], comment: "Composite index for project milestone progress"

    add_check_constraint :milestones,
      "status IN ('pending', 'in_progress', 'completed', 'cancelled')",
      name: "milestones_status_check"

    # Agreements table
    create_table :agreements do |t|
      t.string :agreement_type, null: false
      t.string :status, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.references :project, null: false, foreign_key: true
      t.text :terms

      # Payment details
      t.string :payment_type, null: false
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.decimal :equity_percentage, precision: 5, scale: 2
      t.integer :weekly_hours, null: false
      t.text :tasks, null: false
      t.integer :milestone_ids, array: true, default: []

      t.timestamps null: false
    end

    # Agreement indexes and constraints
    add_index :agreements, :project_id
    add_index :agreements, :status, comment: "Improves filtering by agreement status"
    add_index :agreements, :agreement_type, comment: "Improves filtering by mentorship/co-founder type"
    add_index :agreements, :payment_type
    add_index :agreements, :created_at, comment: "Improves ordering by creation date"
    add_index :agreements, [:status, :agreement_type], comment: "Composite index for combined filtering"

    add_check_constraint :agreements,
      "agreement_type IN ('Mentorship', 'Co-Founder')",
      name: "agreements_type_check"
    add_check_constraint :agreements,
      "status IN ('Pending', 'Accepted', 'Completed', 'Rejected', 'Cancelled', 'Countered')",
      name: "agreements_status_check"
    add_check_constraint :agreements,
      "payment_type IN ('Hourly', 'Equity', 'Hybrid')",
      name: "agreements_payment_type_check"
    add_check_constraint :agreements,
      "end_date > start_date",
      name: "agreements_date_order_check"
    add_check_constraint :agreements,
      "hourly_rate >= 0",
      name: "agreements_hourly_rate_check"
    add_check_constraint :agreements,
      "equity_percentage >= 0 AND equity_percentage <= 100",
      name: "agreements_equity_percentage_check"
    add_check_constraint :agreements,
      "weekly_hours > 0 AND weekly_hours <= 40",
      name: "agreements_weekly_hours_check"

    # Agreement participants table
    create_table :agreement_participants do |t|
      t.references :agreement, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :user_role, null: false
      t.references :project, null: false, foreign_key: true
      t.boolean :is_initiator, default: false
      t.references :counter_agreement, foreign_key: { to_table: :agreements }
      t.references :accept_or_counter_turn, foreign_key: { to_table: :users }
      t.timestamps null: false
    end

    # Agreement participant indexes
    add_index :agreement_participants, :project_id
    add_index :agreement_participants, :user_id
    add_index :agreement_participants, :counter_agreement_id
    add_index :agreement_participants, :accept_or_counter_turn_id
    add_index :agreement_participants, :is_initiator, name: "idx_agreement_participants_on_is_initiator"
    add_index :agreement_participants, [:agreement_id, :user_id],
      unique: true, name: "idx_agreement_participants_on_agreement_user"

    # Meetings table
    create_table :meetings do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.references :agreement, null: false, foreign_key: true
      t.string :google_calendar_event_id
      t.timestamps null: false
    end

    # Meeting indexes and constraints
    add_index :meetings, :agreement_id
    add_index :meetings, :google_calendar_event_id
    add_index :meetings, :start_time, comment: "Improves meeting ordering and time-based queries"
    add_index :meetings, :end_time, comment: "Improves past/upcoming meeting queries"
    add_index :meetings, [:agreement_id, :start_time], comment: "Composite index for agreement meetings ordered by time"

    add_check_constraint :meetings,
      "end_time > start_time",
      name: "meetings_time_order_check"
  end
end
