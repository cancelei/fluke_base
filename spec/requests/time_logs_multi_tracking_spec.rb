# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "TimeLogs multi-project tracking", type: :request do
  let(:user) { create(:user) }
  let(:project_a) { create(:project, user:) }
  let(:project_b) { create(:project, user:) }
  let!(:milestone_a) { create(:milestone, project: project_a) }
  let!(:milestone_b) { create(:milestone, project: project_b) }

  before do
    sign_in user
  end

  def start_tracking(project, milestone)
    post time_logs_path(project.id), params: { milestone_id: milestone.id }
    expect(response).to have_http_status(:redirect).or have_http_status(:ok)
  end

  def stop_tracking(project, milestone)
    post stop_tracking_time_logs_path(project.id), params: { milestone_id: milestone.id }
    expect(response).to have_http_status(:redirect).or have_http_status(:ok)
  end

  context "when multi-project tracking is disabled" do
    before { user.update!(multi_project_tracking: false) }

    it "does not allow starting a second active log on another project" do
      start_tracking(project_a, milestone_a)
      expect(TimeLog.in_progress.where(user:).count).to eq(1)

      start_tracking(project_b, milestone_b)

      # Should still be only one active log due to guard
      expect(TimeLog.in_progress.where(user:).count).to eq(1)
    end
  end

  context "when multi-project tracking is enabled" do
    before { user.update!(multi_project_tracking: true) }

    it "allows one active log per project" do
      start_tracking(project_a, milestone_a)
      start_tracking(project_b, milestone_b)

      expect(TimeLog.in_progress.where(user:, project: project_a).count).to eq(1)
      expect(TimeLog.in_progress.where(user:, project: project_b).count).to eq(1)

      stop_tracking(project_a, milestone_a)
      expect(TimeLog.in_progress.where(user:, project: project_a).count).to eq(0)
      expect(TimeLog.in_progress.where(user:, project: project_b).count).to eq(1)
    end
  end
end
