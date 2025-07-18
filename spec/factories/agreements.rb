FactoryBot.define do
  factory :agreement do
    agreement_type { "MyString" }
    status { "MyString" }
    start_date { "2025-04-09" }
    end_date { "2025-04-09" }
    initiator_id { 1 }
    other_party_id { 1 }
    project { nil }
    terms { "MyText" }
  end
end
