# frozen_string_literal: true

class CreateWedoTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :wedo_tasks do |t|
      # Core task identification
      t.string :task_id, null: false          # e.g., "WISH-YTA", "META-01"
      t.text :description, null: false
      t.string :external_id                   # UUID for CLI sync tracking

      # Status and workflow
      t.string :status, default: "pending", null: false
      t.string :dependency, default: "AGENT_CAPABLE", null: false
      t.string :scope, default: "global", null: false
      t.string :priority, default: "normal", null: false

      # Audit trail
      t.text :synthesis_report, default: ""   # Markdown audit trail of changes
      t.integer :version, default: 0, null: false  # Optimistic locking

      # References and metadata
      t.string :artifact_path                 # Local file reference
      t.string :remote_url                    # GitHub PR/issue URL
      t.string :template_id                   # Template it was created from
      t.date :due_date

      # JSONB columns for arrays
      t.jsonb :blocked_by, default: []        # Array of task_ids that block this
      t.jsonb :tags, default: []              # Array of tag strings

      # Timestamps
      t.datetime :completed_at

      # Relationships
      t.references :project, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.references :assignee, foreign_key: { to_table: :users }
      t.references :parent_task, foreign_key: { to_table: :wedo_tasks }

      t.timestamps
    end

    # Unique constraint: task_id must be unique within a project
    add_index :wedo_tasks, [:project_id, :task_id], unique: true

    # External ID for CLI sync (unique when present)
    add_index :wedo_tasks, :external_id, unique: true, where: "external_id IS NOT NULL"

    # Query optimization indexes
    add_index :wedo_tasks, [:project_id, :status]
    add_index :wedo_tasks, [:project_id, :scope]
    # parent_task_id and assignee_id indexes are auto-created by t.references
    add_index :wedo_tasks, :created_at

    # GIN index for JSONB tag searching
    add_index :wedo_tasks, :tags, using: :gin
  end
end
