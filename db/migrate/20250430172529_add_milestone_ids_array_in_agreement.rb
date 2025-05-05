class AddMilestoneIdsArrayInAgreement < ActiveRecord::Migration[8.0]
  def change
    add_column :agreements, :milestone_ids, :integer, array: true, default: []
  end
end
