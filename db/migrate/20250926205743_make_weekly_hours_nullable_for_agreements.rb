class MakeWeeklyHoursNullableForAgreements < ActiveRecord::Migration[8.0]
  def change
    # Make weekly_hours nullable for co-founder agreements
    change_column_null :agreements, :weekly_hours, true

    # Update the check constraint to allow null values
    if check_constraint_exists?(:agreements, name: "agreements_weekly_hours_check")
      remove_check_constraint :agreements, name: "agreements_weekly_hours_check"
    end

    unless check_constraint_exists?(:agreements, name: "agreements_weekly_hours_check")
      add_check_constraint :agreements,
        "weekly_hours IS NULL OR (weekly_hours > 0 AND weekly_hours <= 40)",
        name: "agreements_weekly_hours_check"
    end
  end
end
