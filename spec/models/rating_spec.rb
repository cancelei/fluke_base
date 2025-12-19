# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rating, type: :model do
  let(:rater) { create(:user) }
  let(:rateable) { create(:user) }

  describe "associations" do
    it { is_expected.to belong_to(:rater).class_name("User") }
    it { is_expected.to belong_to(:rateable) }
  end

  describe "validations" do
    subject { build(:rating, rater: rater, rateable: rateable) }

    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_inclusion_of(:value).in_range(1..5).with_message("must be between 1 and 5") }

    it "validates uniqueness of rater per rateable" do
      create(:rating, rater: rater, rateable: rateable, value: 4)
      duplicate = build(:rating, rater: rater, rateable: rateable, value: 5)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:rater_id]).to include("has already rated this")
    end

    it "prevents users from rating themselves" do
      self_rating = build(:rating, rater: rater, rateable: rater, value: 5)

      expect(self_rating).not_to be_valid
      expect(self_rating.errors[:base]).to include("You cannot rate yourself")
    end
  end

  describe "scopes" do
    let!(:rating1) { create(:rating, rater: rater, rateable: rateable, value: 4) }
    let!(:rating2) { create(:rating, rater: create(:user), rateable: rateable, value: 5) }

    describe ".for_user" do
      it "returns ratings for a specific user" do
        expect(Rating.for_user(rateable)).to contain_exactly(rating1, rating2)
      end
    end

    describe ".by_user" do
      it "returns ratings given by a specific user" do
        expect(Rating.by_user(rater)).to contain_exactly(rating1)
      end
    end
  end

  describe "class methods" do
    before do
      create(:rating, rater: create(:user), rateable: rateable, value: 4)
      create(:rating, rater: create(:user), rateable: rateable, value: 5)
      create(:rating, rater: create(:user), rateable: rateable, value: 3)
    end

    describe ".average_rating" do
      it "calculates the average of all ratings" do
        expect(Rating.for_user(rateable).average_rating).to eq(4.0)
      end
    end

    describe ".rating_breakdown" do
      it "returns a hash of value counts" do
        breakdown = Rating.for_user(rateable).rating_breakdown

        expect(breakdown[3]).to eq(1)
        expect(breakdown[4]).to eq(1)
        expect(breakdown[5]).to eq(1)
      end
    end

    describe ".rating_count" do
      it "returns the total number of ratings" do
        expect(Rating.for_user(rateable).rating_count).to eq(3)
      end
    end
  end
end
