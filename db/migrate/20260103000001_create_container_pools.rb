# frozen_string_literal: true

class CreateContainerPools < ActiveRecord::Migration[7.1]
  def change
    create_table :container_pools do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "active"
      t.integer :warm_pool_size, null: false, default: 1
      t.integer :max_pool_size, null: false, default: 3
      t.integer :context_threshold_percent, null: false, default: 80
      t.boolean :auto_delegate_enabled, null: false, default: true
      t.boolean :skip_user_required, null: false, default: true
      t.datetime :last_activity_at
      t.jsonb :config, null: false, default: {}

      t.timestamps
    end

    add_index :container_pools, :status
  end
end
