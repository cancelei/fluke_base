class CreateAiProductivityMetrics < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_productivity_metrics do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :metric_type, null: false
      t.string :period_type, null: false, default: "session"
      t.datetime :period_start, null: false
      t.datetime :period_end, null: false
      t.jsonb :metric_data, null: false, default: {}
      t.string :external_id  # UUID from flukebase_connect
      t.datetime :synced_at

      t.timestamps

      t.index :metric_type
      t.index :period_type
      t.index %i[project_id metric_type period_start]
      t.index :external_id, unique: true, where: "external_id IS NOT NULL"
    end

    # Add check constraints for valid types
    execute <<~SQL
      ALTER TABLE ai_productivity_metrics
      ADD CONSTRAINT ai_productivity_metrics_metric_type_check
      CHECK (metric_type IN ('time_saved', 'code_contribution', 'task_velocity', 'token_efficiency'))
    SQL

    execute <<~SQL
      ALTER TABLE ai_productivity_metrics
      ADD CONSTRAINT ai_productivity_metrics_period_type_check
      CHECK (period_type IN ('session', 'daily', 'weekly', 'monthly'))
    SQL
  end
end
