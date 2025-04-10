FactoryBot.define do
  factory :agreement do
    agreement_type { "MyString" }
    status { "MyString" }
    start_date { "2025-04-09" }
    end_date { "2025-04-09" }
    entrepreneur_id { 1 }
    mentor_id { 1 }
    project { nil }
    terms { "MyText" }
  end
end
