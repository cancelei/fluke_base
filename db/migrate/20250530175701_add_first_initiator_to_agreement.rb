class AddFirstInitiatorToAgreement < ActiveRecord::Migration[8.0]
  def change
    add_column :agreements, :initiator_meta, :jsonb, default: { id: nil, role: nil }, null: false
    add_column :agreements, :agreement_meta, :jsonb, array: true, default: []
    add_reference :agreements, :counter_offer_turn, foreign_key: { to_table: :users }
  end
end
