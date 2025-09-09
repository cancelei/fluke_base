class CreateSolidCableTables < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_cable_messages do |t|
      t.binary :channel, null: false
      t.binary :payload, null: false
      t.bigint :channel_hash, null: false
      t.datetime :created_at, null: false

      t.index :channel
      t.index :channel_hash
      t.index :created_at
    end
  end
end
