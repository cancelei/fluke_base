# frozen_string_literal: true

class CreateProjectMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :project_memberships do |t|
      t.references :project, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.string :role, null: false, default: "member"
      t.datetime :invited_at
      t.datetime :accepted_at
      t.references :invited_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :project_memberships, [:project_id, :user_id], unique: true
    add_index :project_memberships, [:user_id, :role]

    # Add check constraint for valid roles
    add_check_constraint :project_memberships,
      "role IN ('owner', 'admin', 'member', 'guest')",
      name: "project_memberships_role_check"
  end
end
