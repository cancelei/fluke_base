# frozen_string_literal: true

require "rails_helper"

RSpec.describe AiInsightsService do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }

  describe "#dashboard_insights" do
    subject(:service) { described_class.new(user:, project:) }

    context "with no metrics" do
      it "returns empty array" do
        expect(service.dashboard_insights).to eq([])
      end
    end

    context "with time_saved metrics" do
      before do
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { "time_saved_minutes" => 30, "ai_time_ms" => 60000, "efficiency_ratio" => 3.0 })
      end

      it "includes time_saved insight" do
        insights = service.dashboard_insights
        time_insight = insights.find { |i| i[:type] == :time_saved }

        expect(time_insight).to be_present
        expect(time_insight[:title]).to eq("Time Saved by AI")
        expect(time_insight[:has_data]).to be true
      end

      it "calculates correct summary" do
        insights = service.dashboard_insights
        time_insight = insights.find { |i| i[:type] == :time_saved }

        expect(time_insight[:summary][:total_saved_minutes]).to eq(30)
      end
    end

    context "with code_contribution metrics" do
      before do
        create(:ai_productivity_metric, :code_contribution, project:, user:,
               metric_data: { "lines_added" => 100, "lines_removed" => 20, "commits" => 5 })
      end

      it "includes code_contribution insight" do
        insights = service.dashboard_insights
        code_insight = insights.find { |i| i[:type] == :code_contribution }

        expect(code_insight).to be_present
        expect(code_insight[:title]).to eq("Code Contributions")
      end
    end

    context "with task_velocity metrics" do
      before do
        create(:ai_productivity_metric, :task_velocity, project:, user:,
               metric_data: { "tasks_completed" => 10, "tasks_created" => 12, "completion_rate" => 0.83 })
      end

      it "includes task_velocity insight" do
        insights = service.dashboard_insights
        task_insight = insights.find { |i| i[:type] == :task_velocity }

        expect(task_insight).to be_present
        expect(task_insight[:title]).to eq("Task Velocity")
      end
    end

    context "with token_efficiency metrics" do
      before do
        create(:ai_productivity_metric, :token_efficiency, project:, user:,
               metric_data: { "total_tokens" => 50000, "input_tokens" => 30000, "output_tokens" => 20000, "estimated_cost_usd" => 0.50 })
      end

      it "includes token_efficiency insight" do
        insights = service.dashboard_insights
        token_insight = insights.find { |i| i[:type] == :token_efficiency }

        expect(token_insight).to be_present
        expect(token_insight[:title]).to eq("Token Usage")
      end
    end

    context "with all metric types" do
      before do
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { "time_saved_minutes" => 30 })
        create(:ai_productivity_metric, :code_contribution, project:, user:,
               metric_data: { "lines_added" => 100, "lines_removed" => 10 })
        create(:ai_productivity_metric, :task_velocity, project:, user:,
               metric_data: { "tasks_completed" => 5, "tasks_created" => 5 })
        create(:ai_productivity_metric, :token_efficiency, project:, user:,
               metric_data: { "total_tokens" => 10000 })
      end

      it "returns insights sorted by priority" do
        insights = service.dashboard_insights
        types = insights.map { |i| i[:type] }

        expect(types).to eq(%i[time_saved code_contribution task_velocity token_efficiency])
      end

      it "respects limit parameter" do
        insights = service.dashboard_insights(limit: 2)

        expect(insights.size).to eq(2)
        expect(insights.first[:type]).to eq(:time_saved)
      end
    end

    context "with metrics below threshold" do
      before do
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { "time_saved_minutes" => 2 }) # Below 5 minute threshold
      end

      it "excludes insights below threshold" do
        insights = service.dashboard_insights

        expect(insights).to be_empty
      end
    end
  end

  describe "#time_saved_summary" do
    subject(:service) { described_class.new(user:, project:) }

    context "with no metrics" do
      it "returns zero values" do
        summary = service.time_saved_summary

        expect(summary[:total_saved_minutes]).to eq(0)
        expect(summary[:sessions]).to eq(0)
      end
    end

    context "with metrics" do
      before do
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { "time_saved_minutes" => 30, "ai_time_ms" => 120000 })
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { "time_saved_minutes" => 45, "ai_time_ms" => 180000 })
      end

      it "aggregates time saved" do
        summary = service.time_saved_summary

        expect(summary[:total_saved_minutes]).to eq(75)
        expect(summary[:total_saved_hours]).to eq(1.25)
        expect(summary[:sessions]).to eq(2)
      end

      it "calculates AI time in minutes" do
        summary = service.time_saved_summary

        expect(summary[:ai_time_minutes]).to eq(5.0) # (120000 + 180000) / 60000
      end
    end

    context "with period filter" do
      before do
        create(:ai_productivity_metric, :time_saved, project:, user:,
               period_start: 2.days.ago, period_end: 1.day.ago,
               metric_data: { "time_saved_minutes" => 30 })
        create(:ai_productivity_metric, :time_saved, project:, user:,
               period_start: 10.days.ago, period_end: 9.days.ago,
               metric_data: { "time_saved_minutes" => 100 })
      end

      it "filters by day period" do
        summary = service.time_saved_summary(period: :day)

        expect(summary[:total_saved_minutes]).to eq(0) # Only last 24 hours
      end

      it "includes all in week period" do
        summary = service.time_saved_summary(period: :week)

        expect(summary[:total_saved_minutes]).to eq(30)
      end

      it "includes all in month period" do
        summary = service.time_saved_summary(period: :month)

        expect(summary[:total_saved_minutes]).to eq(130)
      end
    end
  end

  describe "#code_contribution_summary" do
    subject(:service) { described_class.new(user:, project:) }

    before do
      create(:ai_productivity_metric, :code_contribution, project:, user:,
             metric_data: { "lines_added" => 100, "lines_removed" => 20, "net_lines" => 80, "files_changed" => 5, "commits" => 3 })
      create(:ai_productivity_metric, :code_contribution, project:, user:,
             metric_data: { "lines_added" => 50, "lines_removed" => 10, "net_lines" => 40, "files_changed" => 2, "commits" => 2 })
    end

    it "aggregates code contributions" do
      summary = service.code_contribution_summary

      expect(summary[:lines_added]).to eq(150)
      expect(summary[:lines_removed]).to eq(30)
      expect(summary[:net_lines]).to eq(120)
      expect(summary[:files_changed]).to eq(7)
      expect(summary[:commits]).to eq(5)
    end
  end

  describe "#task_velocity_summary" do
    subject(:service) { described_class.new(user:, project:) }

    before do
      create(:ai_productivity_metric, :task_velocity, project:, user:,
             metric_data: { "tasks_completed" => 5, "tasks_created" => 8 })
      create(:ai_productivity_metric, :task_velocity, project:, user:,
             metric_data: { "tasks_completed" => 3, "tasks_created" => 4 })
    end

    it "aggregates task metrics" do
      summary = service.task_velocity_summary

      expect(summary[:tasks_completed]).to eq(8)
      expect(summary[:tasks_created]).to eq(12)
    end

    it "calculates completion rate" do
      summary = service.task_velocity_summary

      expect(summary[:completion_rate]).to be_within(0.01).of(0.667)
    end

    it "calculates velocity per day" do
      summary = service.task_velocity_summary(period: :week)

      expect(summary[:velocity_per_day]).to be > 0
    end
  end

  describe "#token_efficiency_summary" do
    subject(:service) { described_class.new(user:, project:) }

    before do
      create(:ai_productivity_metric, :token_efficiency, project:, user:,
             metric_data: { "total_tokens" => 100000, "input_tokens" => 60000, "output_tokens" => 40000, "estimated_cost_usd" => 1.50 })
    end

    it "aggregates token usage" do
      summary = service.token_efficiency_summary

      expect(summary[:total_tokens]).to eq(100000)
      expect(summary[:input_tokens]).to eq(60000)
      expect(summary[:output_tokens]).to eq(40000)
    end

    it "calculates cost metrics" do
      summary = service.token_efficiency_summary

      expect(summary[:estimated_cost_usd]).to eq(1.5)
      expect(summary[:cost_per_1k_tokens]).to be_within(0.001).of(0.015)
    end
  end

  describe "#mark_insight_seen" do
    subject(:service) { described_class.new(user:, project:) }

    it "marks insight as seen in onboarding progress" do
      service.mark_insight_seen(:time_saved_intro)

      expect(user.onboarding_progress.insight_seen?("time_saved_intro")).to be true
    end
  end

  describe "#full_summary" do
    subject(:service) { described_class.new(user:, project:) }

    before do
      create(:ai_productivity_metric, :time_saved, project:, user:,
             metric_data: { "time_saved_minutes" => 30 })
    end

    it "includes all summary types" do
      summary = service.full_summary

      expect(summary).to have_key(:time_saved)
      expect(summary).to have_key(:code_contribution)
      expect(summary).to have_key(:task_velocity)
      expect(summary).to have_key(:token_efficiency)
      expect(summary).to have_key(:onboarding)
    end
  end

  describe "#onboarding_summary" do
    subject(:service) { described_class.new(user:, project:) }

    it "returns onboarding progress data" do
      summary = service.onboarding_summary

      expect(summary[:stage]).to eq(:new_user)
      expect(summary[:progress_percentage]).to be_a(Integer)
      expect(summary[:complete]).to be false
    end

    context "with completed onboarding" do
      before do
        user.create_onboarding_progress!(
          onboarding_stage: 5,
          milestones_completed: UserOnboardingProgress::MILESTONE_KEYS,
          insights_seen: UserOnboardingProgress::INSIGHT_KEYS,
          onboarding_completed_at: 1.day.ago
        )
      end

      it "shows complete status" do
        summary = service.onboarding_summary

        expect(summary[:stage]).to eq(:onboarding_complete)
        expect(summary[:complete]).to be true
      end
    end
  end

  describe "without project" do
    subject(:service) { described_class.new(user:, project: nil) }

    before do
      create(:ai_productivity_metric, :time_saved, project:, user:,
             metric_data: { "time_saved_minutes" => 30 })
    end

    it "queries user metrics directly" do
      summary = service.time_saved_summary

      expect(summary[:total_saved_minutes]).to eq(30)
    end
  end
end
