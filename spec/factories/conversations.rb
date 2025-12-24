# == Schema Information
#
# Table name: conversations
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  recipient_id :bigint           not null
#  sender_id    :bigint           not null
#
# Indexes
#
#  index_conversations_on_recipient_and_sender  (recipient_id,sender_id) UNIQUE
#  index_conversations_on_sender_id             (sender_id)
#
# Foreign Keys
#
#  fk_rails_...  (recipient_id => users.id)
#  fk_rails_...  (sender_id => users.id)
#
FactoryBot.define do
  factory :conversation do
    association :sender, factory: :user
    association :recipient, factory: :user
  end
end
