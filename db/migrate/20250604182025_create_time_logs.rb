class CreateTimeLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :time_logs do |t|
      t.references :agreement, null: false, foreign_key: true
      t.references :milestone, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.text :description
      t.decimal :hours_spent, precision: 10, scale: 2, default: 0.0
      t.string :status, default: 'in_progress'

      t.timestamps
    end

    add_index :time_logs, [:agreement_id, :milestone_id]
  end
end
