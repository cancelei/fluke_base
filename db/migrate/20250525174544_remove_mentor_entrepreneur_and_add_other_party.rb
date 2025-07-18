class RemoveMentorEntrepreneurAndAddOtherParty < ActiveRecord::Migration[8.0]
  def change
    # Remove the mentor and entrepreneur columns from agreements
    remove_column :agreements, :mentor_id, :integer
    remove_column :agreements, :entrepreneur_id, :integer

    # Add a new column for other_party
    add_reference :agreements, :other_party, foreign_key: { to_table: :users }, null: true
  end
end
