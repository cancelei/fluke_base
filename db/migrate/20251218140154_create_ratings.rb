class CreateRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :ratings do |t|
      t.references :rater, null: false, foreign_key: { to_table: :users }
      t.references :rateable, polymorphic: true, null: false
      t.integer :value, null: false
      t.text :review

      t.timestamps
    end

    # Ensure one rating per rater per rateable
    add_index :ratings, [:rater_id, :rateable_type, :rateable_id], unique: true, name: "index_ratings_uniqueness"

    # Ensure value is between 1 and 5
    add_check_constraint :ratings, "value >= 1 AND value <= 5", name: "ratings_value_range"
  end
end
