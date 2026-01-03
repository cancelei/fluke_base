# frozen_string_literal: true

class CreateDelegationRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :delegation_requests do |t|
      t.references :project, null: false, foreign_key: true
      t.references :wedo_task, null: false, foreign_key: true
      t.references :container_session, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :requested_by_session
      t.datetime :claimed_at
      t.datetime :completed_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :delegation_requests, [:project_id, :status]
    add_index :delegation_requests, [:wedo_task_id, :status]
  end
end
