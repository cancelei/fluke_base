# frozen_string_literal: true

# == Schema Information
#
# Table name: ai_productivity_metrics
#
#  id           :bigint           not null, primary key
#  metric_data  :jsonb            not null
#  metric_type  :string           not null
#  period_end   :datetime         not null
#  period_start :datetime         not null
#  period_type  :string           default("session"), not null
#  synced_at    :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string
#  project_id   :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  idx_on_project_id_metric_type_period_start_c4a679eb0b  (project_id,metric_type,period_start)
#  index_ai_productivity_metrics_on_external_id           (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#  index_ai_productivity_metrics_on_metric_type           (metric_type)
#  index_ai_productivity_metrics_on_period_type           (period_type)
#  index_ai_productivity_metrics_on_project_id            (project_id)
#  index_ai_productivity_metrics_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe AiProductivityMetric, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }

  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:metric_type) }
    it { is_expected.to validate_presence_of(:period_type) }
    it { is_expected.to validate_presence_of(:period_start) }
    it { is_expected.to validate_presence_of(:period_end) }
    it { is_expected.to validate_inclusion_of(:metric_type).in_array(AiProductivityMetric::METRIC_TYPES) }
    it { is_expected.to validate_inclusion_of(:period_type).in_array(AiProductivityMetric::PERIOD_TYPES) }
  end

  describe "metric types" do
    it "defines all expected types" do
      expect(AiProductivityMetric::METRIC_TYPES).to eq(%w[time_saved code_contribution task_velocity token_efficiency])
    end
  end

  describe "period types" do
    it "defines all expected period types" do
      expect(AiProductivityMetric::PERIOD_TYPES).to eq(%w[session daily weekly monthly])
    end
  end

  describe "scopes" do
    let!(:time_saved) { create(:ai_productivity_metric, :time_saved, project:, user:) }
    let!(:code_contribution) { create(:ai_productivity_metric, :code_contribution, project:, user:) }
    let!(:task_velocity) { create(:ai_productivity_metric, :task_velocity, project:, user:) }
    let!(:token_efficiency) { create(:ai_productivity_metric, :token_efficiency, project:, user:) }

    describe ".time_saved" do
      it "returns only time_saved metrics" do
        expect(AiProductivityMetric.time_saved).to contain_exactly(time_saved)
      end
    end

    describe ".code_contributions" do
      it "returns only code_contribution metrics" do
        expect(AiProductivityMetric.code_contributions).to contain_exactly(code_contribution)
      end
    end

    describe ".task_velocity" do
      it "returns only task_velocity metrics" do
        expect(AiProductivityMetric.task_velocity).to contain_exactly(task_velocity)
      end
    end

    describe ".token_efficiency" do
      it "returns only token_efficiency metrics" do
        expect(AiProductivityMetric.token_efficiency).to contain_exactly(token_efficiency)
      end
    end
  end

  describe "period scopes" do
    let!(:session_metric) { create(:ai_productivity_metric, project:, user:, period_type: "session") }
    let!(:daily_metric) { create(:ai_productivity_metric, :daily, project:, user:) }
    let!(:weekly_metric) { create(:ai_productivity_metric, :weekly, project:, user:) }

    describe ".for_period" do
      it "filters by period type" do
        expect(AiProductivityMetric.for_period("session")).to contain_exactly(session_metric)
        expect(AiProductivityMetric.for_period("daily")).to contain_exactly(daily_metric)
        expect(AiProductivityMetric.for_period("weekly")).to contain_exactly(weekly_metric)
      end
    end
  end

  describe ".since" do
    let!(:old_metric) { create(:ai_productivity_metric, project:, user:, period_start: 2.days.ago, period_end: 2.days.ago + 1.hour) }
    let!(:new_metric) { create(:ai_productivity_metric, project:, user:, period_start: 1.hour.ago, period_end: Time.current) }

    it "returns metrics with period_start since given time" do
      expect(AiProductivityMetric.since(1.day.ago)).to contain_exactly(new_metric)
    end
  end

  describe "sync scopes" do
    let!(:synced) { create(:ai_productivity_metric, :synced, project:, user:) }
    let!(:unsynced) { create(:ai_productivity_metric, project:, user:, synced_at: nil) }

    describe ".synced" do
      it "returns only synced metrics" do
        expect(AiProductivityMetric.synced).to contain_exactly(synced)
      end
    end

    describe ".unsynced" do
      it "returns only unsynced metrics" do
        expect(AiProductivityMetric.unsynced).to contain_exactly(unsynced)
      end
    end
  end

  describe ".aggregate_for_project" do
    let!(:metric1) do
      create(:ai_productivity_metric, :time_saved, project:, user:,
             metric_data: { "time_saved_minutes" => 10 })
    end
    let!(:metric2) do
      create(:ai_productivity_metric, :time_saved, project:, user:,
             metric_data: { "time_saved_minutes" => 15 })
    end

    it "aggregates metrics for a project" do
      result = AiProductivityMetric.aggregate_for_project(project.id)
      expect(result).to be_a(Hash)
      expect(result[:time_saved]).to be_present
    end
  end

  describe ".aggregate_time_saved" do
    before do
      create(:ai_productivity_metric, :time_saved, project:, user:,
             metric_data: { "time_saved_ms" => 600_000, "ai_time_ms" => 60_000 })  # 10 minutes
      create(:ai_productivity_metric, :time_saved, project:, user:,
             metric_data: { "time_saved_ms" => 1_200_000, "ai_time_ms" => 120_000 })  # 20 minutes
    end

    it "sums time saved in milliseconds and converts to minutes" do
      result = AiProductivityMetric.aggregate_time_saved(project.ai_productivity_metrics.time_saved)
      expect(result[:total_time_saved_minutes]).to eq(30.0)
    end

    it "calculates hours" do
      result = AiProductivityMetric.aggregate_time_saved(project.ai_productivity_metrics.time_saved)
      expect(result[:total_time_saved_hours]).to eq(0.5)
    end
  end

  describe ".aggregate_code_contribution" do
    before do
      create(:ai_productivity_metric, :code_contribution, project:, user:,
             metric_data: { "lines_added" => 100, "lines_removed" => 20, "total_commits" => 3, "files_changed" => 5 })
      create(:ai_productivity_metric, :code_contribution, project:, user:,
             metric_data: { "lines_added" => 50, "lines_removed" => 10, "total_commits" => 2, "files_changed" => 3 })
    end

    it "sums code contribution stats" do
      result = AiProductivityMetric.aggregate_code_contribution(project.ai_productivity_metrics.code_contributions)
      expect(result[:total_lines_added]).to eq(150)
      expect(result[:total_lines_removed]).to eq(30)
      expect(result[:total_commits]).to eq(5)
    end
  end

  describe "external_id uniqueness" do
    let!(:existing) do
      create(:ai_productivity_metric, :synced, project:, user:, external_id: "unique-ext-id")
    end

    it "allows multiple nil external_ids" do
      metric1 = create(:ai_productivity_metric, project:, user:, external_id: nil)
      metric2 = build(:ai_productivity_metric, project:, user:, external_id: nil)
      expect(metric2).to be_valid
    end
  end
end
