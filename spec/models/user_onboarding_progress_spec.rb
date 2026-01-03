# frozen_string_literal: true

# == Schema Information
#
# Table name: user_onboarding_progress
#
#  id                      :bigint           not null, primary key
#  first_ai_session_at     :datetime
#  first_task_completed_at :datetime
#  insights_seen           :jsonb            not null
#  milestones_completed    :jsonb            not null
#  onboarding_completed_at :datetime
#  onboarding_stage        :integer          default(0), not null
#  preferences             :jsonb            not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_user_onboarding_progress_on_onboarding_stage  (onboarding_stage)
#  index_user_onboarding_progress_on_user_id           (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe UserOnboardingProgress, type: :model do
  let(:user) { create(:user) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:onboarding_stage) }

    it "validates onboarding_stage is within range" do
      progress = build(:user_onboarding_progress, user:, onboarding_stage: -1)
      expect(progress).not_to be_valid

      progress.onboarding_stage = 6
      expect(progress).not_to be_valid

      progress.onboarding_stage = 3
      expect(progress).to be_valid
    end
  end

  describe "constants" do
    it "defines onboarding stages" do
      expect(UserOnboardingProgress::ONBOARDING_STAGES).to eq({
        new_user: 0,
        first_connection: 1,
        first_ai_session: 2,
        first_task_completed: 3,
        insights_explored: 4,
        onboarding_complete: 5
      })
    end

    it "defines insight keys" do
      expect(UserOnboardingProgress::INSIGHT_KEYS).to include(
        "time_saved_intro",
        "code_contribution_intro",
        "task_velocity_intro",
        "token_efficiency_intro"
      )
    end

    it "defines milestone keys" do
      expect(UserOnboardingProgress::MILESTONE_KEYS).to include(
        "connected_flukebase",
        "first_ai_session",
        "first_task_completed"
      )
    end
  end

  describe "scopes" do
    let!(:incomplete) { create(:user_onboarding_progress, :first_ai_session) }
    let!(:complete) { create(:user_onboarding_progress, :complete) }

    describe ".incomplete" do
      it "returns only incomplete onboarding records" do
        expect(UserOnboardingProgress.incomplete).to contain_exactly(incomplete)
      end
    end

    describe ".complete" do
      it "returns only complete onboarding records" do
        expect(UserOnboardingProgress.complete).to contain_exactly(complete)
      end
    end

    describe ".at_stage" do
      it "returns records at specific stage" do
        expect(UserOnboardingProgress.at_stage(:first_ai_session)).to contain_exactly(incomplete)
      end
    end
  end

  describe "#mark_insight_seen!" do
    let(:progress) { create(:user_onboarding_progress, user:) }

    it "adds insight to seen list" do
      progress.mark_insight_seen!("time_saved_intro")
      expect(progress.insights_seen).to include("time_saved_intro")
    end

    it "does not duplicate insights" do
      progress.mark_insight_seen!("time_saved_intro")
      progress.mark_insight_seen!("time_saved_intro")
      expect(progress.insights_seen.count("time_saved_intro")).to eq(1)
    end
  end

  describe "#insight_seen?" do
    let(:progress) do
      create(:user_onboarding_progress, user:, insights_seen: ["time_saved_intro"])
    end

    it "returns true for seen insights" do
      expect(progress.insight_seen?("time_saved_intro")).to be true
      expect(progress.insight_seen?(:time_saved_intro)).to be true
    end

    it "returns false for unseen insights" do
      expect(progress.insight_seen?("code_contribution_intro")).to be false
    end
  end

  describe "#mark_milestone_completed!" do
    let(:progress) { create(:user_onboarding_progress, user:) }

    it "adds milestone to completed list" do
      progress.mark_milestone_completed!("connected_flukebase")
      expect(progress.milestones_completed).to include("connected_flukebase")
    end

    it "does not duplicate milestones" do
      progress.mark_milestone_completed!("connected_flukebase")
      progress.mark_milestone_completed!("connected_flukebase")
      expect(progress.milestones_completed.count("connected_flukebase")).to eq(1)
    end
  end

  describe "#milestone_completed?" do
    let(:progress) do
      create(:user_onboarding_progress, user:, milestones_completed: ["connected_flukebase"])
    end

    it "returns true for completed milestones" do
      expect(progress.milestone_completed?("connected_flukebase")).to be true
    end

    it "returns false for incomplete milestones" do
      expect(progress.milestone_completed?("first_ai_session")).to be false
    end
  end

  describe "#advance_stage!" do
    let(:progress) { create(:user_onboarding_progress, user:, onboarding_stage: 0) }

    it "advances to specified stage" do
      progress.advance_stage!(:first_connection)
      expect(progress.onboarding_stage).to eq(1)
    end

    it "does not go backwards" do
      progress.advance_stage!(:first_ai_session)
      progress.advance_stage!(:first_connection)
      expect(progress.onboarding_stage).to eq(2)
    end

    it "sets first_ai_session_at when advancing to that stage" do
      progress.advance_stage!(:first_ai_session)
      expect(progress.first_ai_session_at).to be_present
    end

    it "sets first_task_completed_at when advancing to that stage" do
      progress.advance_stage!(:first_task_completed)
      expect(progress.first_task_completed_at).to be_present
    end

    it "sets onboarding_completed_at when completing" do
      progress.advance_stage!(:onboarding_complete)
      expect(progress.onboarding_completed_at).to be_present
    end
  end

  describe "#current_stage_key" do
    it "returns the stage as a symbol" do
      progress = create(:user_onboarding_progress, user:, onboarding_stage: 2)
      expect(progress.current_stage_key).to eq(:first_ai_session)
    end
  end

  describe "#onboarding_complete?" do
    it "returns true when stage is complete" do
      progress = create(:user_onboarding_progress, :complete)
      expect(progress.onboarding_complete?).to be true
    end

    it "returns false when stage is incomplete" do
      progress = create(:user_onboarding_progress, user:, onboarding_stage: 3)
      expect(progress.onboarding_complete?).to be false
    end
  end

  describe "#unseen_insights" do
    let(:progress) do
      create(:user_onboarding_progress, user:, insights_seen: ["time_saved_intro"])
    end

    it "returns insights not yet seen" do
      unseen = progress.unseen_insights
      expect(unseen).not_to include("time_saved_intro")
      expect(unseen).to include("code_contribution_intro")
    end
  end

  describe "#incomplete_milestones" do
    let(:progress) do
      create(:user_onboarding_progress, user:, milestones_completed: ["connected_flukebase"])
    end

    it "returns milestones not yet completed" do
      incomplete = progress.incomplete_milestones
      expect(incomplete).not_to include("connected_flukebase")
      expect(incomplete).to include("first_ai_session")
    end
  end

  describe "#progress_percentage" do
    it "returns 100 when complete" do
      progress = create(:user_onboarding_progress, :complete)
      expect(progress.progress_percentage).to eq(100)
    end

    it "calculates percentage based on stages, insights, and milestones" do
      progress = create(:user_onboarding_progress, :first_ai_session)
      percentage = progress.progress_percentage
      expect(percentage).to be_between(0, 100)
      expect(percentage).to be > 0
    end
  end

  describe "preferences" do
    let(:progress) { create(:user_onboarding_progress, user:) }

    describe "#preference" do
      it "returns nil for unset preference" do
        expect(progress.preference(:theme)).to be_nil
      end

      it "returns set preference value" do
        progress.set_preference!(:theme, "dark")
        expect(progress.preference(:theme)).to eq("dark")
      end
    end

    describe "#set_preference!" do
      it "sets and persists preference" do
        progress.set_preference!(:show_hints, true)
        progress.reload
        expect(progress.preferences["show_hints"]).to eq(true)
      end
    end
  end
end
