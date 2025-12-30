# frozen_string_literal: true

class CreateWebhookDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_deliveries do |t|
      t.references :webhook_subscription, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :idempotency_key, null: false
      t.integer :status_code
      t.text :response_body
      t.integer :attempt_count, default: 0, null: false
      t.datetime :delivered_at
      t.datetime :next_retry_at
      t.timestamps

      t.index :idempotency_key, unique: true
      t.index %i[webhook_subscription_id created_at]
      t.index :next_retry_at, where: "delivered_at IS NULL"
    end
  end
end
