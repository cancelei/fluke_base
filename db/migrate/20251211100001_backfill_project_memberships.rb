# frozen_string_literal: true

class BackfillProjectMemberships < ActiveRecord::Migration[8.0]
  def up
    # Create owner memberships for existing project owners
    execute <<-SQL.squish
      INSERT INTO project_memberships (project_id, user_id, role, accepted_at, created_at, updated_at)
      SELECT id, user_id, 'owner', NOW(), NOW(), NOW()
      FROM projects
      WHERE user_id IS NOT NULL
      ON CONFLICT (project_id, user_id) DO NOTHING
    SQL

    # Create member memberships for users with active/completed agreements
    execute <<-SQL.squish
      INSERT INTO project_memberships (project_id, user_id, role, accepted_at, created_at, updated_at)
      SELECT DISTINCT a.project_id, ap.user_id, 'member', NOW(), NOW(), NOW()
      FROM agreement_participants ap
      JOIN agreements a ON a.id = ap.agreement_id
      WHERE a.status IN ('Accepted', 'Completed')
        AND a.project_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM project_memberships pm
          WHERE pm.project_id = a.project_id AND pm.user_id = ap.user_id
        )
      ON CONFLICT (project_id, user_id) DO NOTHING
    SQL
  end

  def down
    # Keep memberships - reversing would lose important data
    # If needed, can manually delete:
    # execute "DELETE FROM project_memberships"
  end
end
