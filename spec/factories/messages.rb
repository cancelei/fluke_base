FactoryBot.define do
  factory :message do
    body { "MyText" }
    association :conversation
    association :user
    read { false }
  end
end
