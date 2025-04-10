FactoryBot.define do
  factory :milestone do
    title { "MyString" }
    description { "MyText" }
    due_date { "2025-04-09" }
    status { "MyString" }
    project { nil }
  end
end
