class CreateAgreements < ActiveRecord::Migration[8.0]
  def change
    create_table :agreements do |t|
      t.string :agreement_type
      t.string :status
      t.date :start_date
      t.date :end_date
      t.integer :entrepreneur_id
      t.integer :mentor_id
      t.references :project, null: false, foreign_key: true
      t.text :terms

      t.timestamps
    end
  end
end
