class RemoveUnnecessaryFieldsFromAgreements < ActiveRecord::Migration[8.0]
  def change
    # Remove indexes first
    remove_index :agreements, :counter_offer_turn_id if index_exists?(:agreements, :counter_offer_turn_id)
    remove_index :agreements, :counter_to_id if index_exists?(:agreements, :counter_to_id)

    # Remove the unnecessary columns that are now handled by agreement_participants
    remove_column :agreements, :initiator_meta, :jsonb
    remove_column :agreements, :agreement_meta, :jsonb
    remove_column :agreements, :counter_offer_turn_id, :bigint
    remove_column :agreements, :counter_to_id, :integer
  end
end
