class CreateMeetings < ActiveRecord::Migration[8.0]
  def change
    create_table :meetings do |t|
      t.string :title
      t.text :description
      t.datetime :start_time
      t.datetime :end_time
      t.references :agreement, null: false, foreign_key: true
      t.string :google_calendar_event_id

      t.timestamps
    end
  end
end
