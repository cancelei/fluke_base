class AddInitiatorToAgreement < ActiveRecord::Migration[8.0]
  def change
    add_reference :agreements, :initiator, foreign_key: { to_table: :users }, index: true
  end
end
