class ManualEntryForTimeLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :time_logs, :manual_entry, :boolean, default: false
  end
end
