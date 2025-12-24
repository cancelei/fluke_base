# == Schema Information
#
# Table name: messages
#
#  id              :bigint           not null, primary key
#  body            :text
#  read            :boolean
#  voice           :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_messages_on_conversation_id                 (conversation_id)
#  index_messages_on_conversation_id_and_created_at  (conversation_id,created_at)
#  index_messages_on_created_at                      (created_at)
#  index_messages_on_read                            (read)
#  index_messages_on_user_id                         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :message do
    body { "MyText" }
    association :conversation
    association :user
    read { false }
  end
end
