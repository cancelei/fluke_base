class AddCounterToIdToAgreements < ActiveRecord::Migration[8.0]
  def change
    add_column :agreements, :counter_to_id, :integer
    add_index :agreements, :counter_to_id
  end
end
