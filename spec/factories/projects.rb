FactoryBot.define do
  factory :project do
    name { "MyString" }
    description { "MyText" }
    stage { "MyString" }
    user { nil }
  end
end
