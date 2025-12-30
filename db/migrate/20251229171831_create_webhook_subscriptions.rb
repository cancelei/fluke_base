# frozen_string_literal: true

class CreateWebhookSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_subscriptions do |t|
      t.references :project, null: false, foreign_key: true
      t.references :api_token, null: false, foreign_key: true
      t.string :callback_url, null: false
      t.text :events, array: true, default: ["env.updated"]
      t.string :secret # HMAC signing secret
      t.boolean :active, default: true, null: false
      t.integer :failure_count, default: 0, null: false
      t.datetime :last_failure_at
      t.datetime :last_success_at
      t.timestamps

      t.index %i[project_id active]
      t.index :api_token_id
    end
  end
end
