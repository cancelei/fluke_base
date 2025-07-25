class RemoveInitiatorAndOtherPartyFromAgreements < ActiveRecord::Migration[8.0]
  def up
    # Remove foreign key constraints first
    remove_foreign_key :agreements, column: :initiator_id if foreign_key_exists?(:agreements, column: :initiator_id)
    remove_foreign_key :agreements, column: :other_party_id if foreign_key_exists?(:agreements, column: :other_party_id)

    # Remove indexes
    remove_index :agreements, :initiator_id if index_exists?(:agreements, :initiator_id)
    remove_index :agreements, :other_party_id if index_exists?(:agreements, :other_party_id)

    # Remove columns
    remove_column :agreements, :initiator_id, :bigint
    remove_column :agreements, :other_party_id, :bigint
  end

  def down
    # Add columns back
    add_column :agreements, :initiator_id, :bigint
    add_column :agreements, :other_party_id, :bigint

    # Add indexes back
    add_index :agreements, :initiator_id
    add_index :agreements, :other_party_id

    # Add foreign keys back
    add_foreign_key :agreements, :users, column: :initiator_id
    add_foreign_key :agreements, :users, column: :other_party_id
  end
end
