class AddVoiceToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :voice, :boolean, default: false
  end
end
