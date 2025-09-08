class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Critical indexes for agreements table
    add_index :agreements, :status, comment: "Improves filtering by agreement status"
    add_index :agreements, :agreement_type, comment: "Improves filtering by mentorship/co-founder type"
    add_index :agreements, [ :status, :agreement_type ], comment: "Composite index for combined filtering"
    add_index :agreements, :created_at, comment: "Improves ordering by creation date"

    # Meetings performance indexes
    add_index :meetings, :start_time, comment: "Improves meeting ordering and time-based queries"
    add_index :meetings, :end_time, comment: "Improves past/upcoming meeting queries"
    add_index :meetings, [ :agreement_id, :start_time ], comment: "Composite index for agreement meetings ordered by time"

    # Time logs performance indexes
    add_index :time_logs, :status, comment: "Improves filtering by active/completed time logs"
    add_index :time_logs, :started_at, comment: "Improves time-based queries and reporting"
    add_index :time_logs, [ :project_id, :user_id ], comment: "Composite index for user-project time logs"

    # Notifications performance indexes
    add_index :notifications, :read_at, comment: "Improves unread notifications queries"
    add_index :notifications, [ :user_id, :read_at ], comment: "Composite index for user's unread notifications"
    add_index :notifications, :created_at, comment: "Improves ordering notifications by recency"

    # GitHub logs performance indexes
    add_index :github_logs, :commit_date, comment: "Improves time-based queries for commit history"
    add_index :github_logs, [ :project_id, :commit_date ], comment: "Composite index for project commit timeline"
    add_index :github_logs, [ :user_id, :commit_date ], comment: "Composite index for user commit activity"

    # Messages performance indexes
    add_index :messages, :created_at, comment: "Improves message ordering in conversations"
    add_index :messages, [ :conversation_id, :created_at ], comment: "Composite index for conversation message history"
    add_index :messages, :read, comment: "Improves unread message queries"

    # Projects performance indexes
    add_index :projects, :stage, comment: "Improves filtering by project stage"
    add_index :projects, :collaboration_type, comment: "Improves filtering by seeking mentor/co-founder"
    add_index :projects, :created_at, comment: "Improves ordering by project creation"

    # Milestones performance indexes
    add_index :milestones, :status, comment: "Improves filtering by milestone status"
    add_index :milestones, :due_date, comment: "Improves due date queries and sorting"
    add_index :milestones, [ :project_id, :due_date ], comment: "Composite index for project milestone timeline"
    add_index :milestones, [ :project_id, :status ], comment: "Composite index for project milestone progress"
  end
end
