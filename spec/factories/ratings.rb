# frozen_string_literal: true

# == Schema Information
#
# Table name: ratings
#
#  id            :bigint           not null, primary key
#  rateable_type :string           not null
#  review        :text
#  value         :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  rateable_id   :bigint           not null
#  rater_id      :bigint           not null
#
# Indexes
#
#  index_ratings_on_rateable  (rateable_type,rateable_id)
#  index_ratings_on_rater_id  (rater_id)
#  index_ratings_uniqueness   (rater_id,rateable_type,rateable_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (rater_id => users.id)
#
FactoryBot.define do
  factory :rating do
    association :rater, factory: :user
    association :rateable, factory: :user
    value { rand(1..5) }
    review { nil }

    trait :with_review do
      review { Faker::Lorem.paragraph }
    end

    trait :five_stars do
      value { 5 }
    end

    trait :four_stars do
      value { 4 }
    end

    trait :three_stars do
      value { 3 }
    end

    trait :two_stars do
      value { 2 }
    end

    trait :one_star do
      value { 1 }
    end
  end
end
