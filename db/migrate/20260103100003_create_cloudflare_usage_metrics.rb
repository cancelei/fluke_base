# frozen_string_literal: true

class CreateCloudflareUsageMetrics < ActiveRecord::Migration[8.0]
  def change
    create_table :cloudflare_usage_metrics do |t|
      t.references :cloudflare_worker, foreign_key: true, null: false
      t.date :recorded_date, null: false
      t.string :period_type, default: "daily", null: false
      t.integer :browser_sessions, default: 0
      t.integer :requests_count, default: 0
      t.integer :execution_time_ms, default: 0
      t.decimal :estimated_cost_usd, precision: 10, scale: 4
      t.json :raw_metrics, default: {}

      t.timestamps
    end

    add_index :cloudflare_usage_metrics,
              %i[cloudflare_worker_id recorded_date period_type],
              unique: true,
              name: "idx_cloudflare_usage_metrics_unique"
    add_index :cloudflare_usage_metrics, :recorded_date
  end
end
