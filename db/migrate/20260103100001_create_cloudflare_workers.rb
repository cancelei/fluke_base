# frozen_string_literal: true

class CreateCloudflareWorkers < ActiveRecord::Migration[8.0]
  def change
    create_table :cloudflare_workers do |t|
      t.string :name, null: false
      t.string :account_id, null: false
      t.string :script_hash
      t.string :status, default: "unknown", null: false
      t.string :environment, default: "development", null: false
      t.string :worker_url
      t.datetime :last_deployed_at
      t.datetime :last_health_check_at
      t.json :configuration, default: {}

      t.timestamps
    end

    add_index :cloudflare_workers, :name, unique: true
    add_index :cloudflare_workers, :environment
    add_index :cloudflare_workers, :status
  end
end
