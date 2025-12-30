# frozen_string_literal: true

class CreateApiTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :prefix, null: false, limit: 8
      t.text :scopes, array: true, default: []
      t.datetime :last_used_at
      t.string :last_used_ip
      t.datetime :expires_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :api_tokens, :token_digest, unique: true
    add_index :api_tokens, :prefix
    add_index :api_tokens, [:user_id, :revoked_at]
  end
end
