# frozen_string_literal: true

class CreateBrowserTestRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :browser_test_runs do |t|
      t.references :project, foreign_key: true, null: true
      t.references :cloudflare_worker, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: true
      t.string :test_type, null: false
      t.string :suite_name
      t.string :status, default: "pending", null: false
      t.json :results, default: {}
      t.json :assertions, default: []
      t.text :screenshot_base64
      t.integer :duration_ms
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :browser_test_runs, :test_type
    add_index :browser_test_runs, :status
    add_index :browser_test_runs, :created_at
  end
end
