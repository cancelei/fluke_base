FactoryBot.define do
  factory :agreement do
    agreement_type { "MyString" }
    status { "MyString" }
    start_date { "2025-04-09" }
    end_date { "2025-04-09" }
    # Agreement participants will be created via AgreementForm or test setup
    project { nil }
    terms { "MyText" }
  end
end
