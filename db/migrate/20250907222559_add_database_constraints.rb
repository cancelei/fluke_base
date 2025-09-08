class AddDatabaseConstraints < ActiveRecord::Migration[8.0]
  def change
    # Add check constraints for enum-like fields to ensure data integrity
    # These complement Rails validations and provide database-level enforcement

    # Agreements constraints
    add_check_constraint :agreements,
      "status IN ('Pending', 'Accepted', 'Completed', 'Rejected', 'Cancelled', 'Countered')",
      name: "agreements_status_check"

    add_check_constraint :agreements,
      "agreement_type IN ('Mentorship', 'Co-Founder')",
      name: "agreements_type_check"

    add_check_constraint :agreements,
      "payment_type IN ('Hourly', 'Equity', 'Hybrid')",
      name: "agreements_payment_type_check"

    add_check_constraint :agreements,
      "weekly_hours > 0 AND weekly_hours <= 40",
      name: "agreements_weekly_hours_check"

    add_check_constraint :agreements,
      "end_date > start_date",
      name: "agreements_date_order_check"

    add_check_constraint :agreements,
      "hourly_rate >= 0",
      name: "agreements_hourly_rate_check"

    add_check_constraint :agreements,
      "equity_percentage >= 0 AND equity_percentage <= 100",
      name: "agreements_equity_percentage_check"

    # Time logs constraints
    add_check_constraint :time_logs,
      "status IN ('in_progress', 'completed', 'paused')",
      name: "time_logs_status_check"

    add_check_constraint :time_logs,
      "hours_spent >= 0",
      name: "time_logs_hours_check"

    # Projects constraints
    add_check_constraint :projects,
      "stage IN ('idea', 'prototype', 'launched', 'scaling')",
      name: "projects_stage_check"

    # Meetings constraints
    add_check_constraint :meetings,
      "end_time > start_time",
      name: "meetings_time_order_check"

    # Milestones constraints
    add_check_constraint :milestones,
      "status IN ('pending', 'in_progress', 'completed', 'cancelled')",
      name: "milestones_status_check"
  end
end
