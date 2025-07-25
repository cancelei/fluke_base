class CreateAgreementParticipants < ActiveRecord::Migration[8.0]
  def up
    create_table :agreement_participants do |t|
      t.references :agreement, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :user_role
      t.references :project, null: false, foreign_key: true
      t.boolean :is_initiator, default: false
      t.references :counter_agreement, null: true, foreign_key: { to_table: :agreements }
      t.references :accept_or_counter_turn, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Add indexes for performance
    add_index :agreement_participants, [ :agreement_id, :user_id ], unique: true, name: 'idx_agreement_participants_on_agreement_user'
    add_index :agreement_participants, :is_initiator, name: 'idx_agreement_participants_on_is_initiator'
    add_index :agreement_participants, :accept_or_counter_turn_id, name: 'idx_agreement_participants_on_turn'

    # Migrate existing data from agreements table
    migrate_existing_agreements
  end

  def down
    drop_table :agreement_participants
  end

  private

  def migrate_existing_agreements
    # Use raw SQL to avoid model dependencies during migration
    execute <<~SQL
      INSERT INTO agreement_participants (
        agreement_id, user_id, user_role, project_id, is_initiator,#{' '}
        counter_agreement_id, accept_or_counter_turn_id, created_at, updated_at
      )
      SELECT#{' '}
        a.id as agreement_id,
        a.initiator_id as user_id,
        COALESCE(r.name, 'Unknown') as user_role,
        a.project_id,
        true as is_initiator,
        a.counter_to_id as counter_agreement_id,
        a.counter_offer_turn_id as accept_or_counter_turn_id,
        a.created_at,
        a.updated_at
      FROM agreements a
      JOIN users u ON u.id = a.initiator_id
      LEFT JOIN user_roles ur ON ur.user_id = u.id
      LEFT JOIN roles r ON r.id = ur.role_id
      WHERE a.initiator_id IS NOT NULL;
    SQL

    execute <<~SQL
      INSERT INTO agreement_participants (
        agreement_id, user_id, user_role, project_id, is_initiator,
        counter_agreement_id, accept_or_counter_turn_id, created_at, updated_at
      )
      SELECT#{' '}
        a.id as agreement_id,
        a.other_party_id as user_id,
        COALESCE(r.name, 'Unknown') as user_role,
        a.project_id,
        false as is_initiator,
        a.counter_to_id as counter_agreement_id,
        a.counter_offer_turn_id as accept_or_counter_turn_id,
        a.created_at,
        a.updated_at
      FROM agreements a
      JOIN users u ON u.id = a.other_party_id
      LEFT JOIN user_roles ur ON ur.user_id = u.id
      LEFT JOIN roles r ON r.id = ur.role_id
      WHERE a.other_party_id IS NOT NULL;
    SQL
  end
end
