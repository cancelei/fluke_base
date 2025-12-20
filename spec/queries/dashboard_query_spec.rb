require 'rails_helper'

RSpec.describe DashboardQuery do
  let(:user) { create(:user) }
  subject(:query) { described_class.new(user) }

  describe '#recent_projects' do
    let!(:older) { create(:project, user:, created_at: 2.days.ago) }
    let!(:newer) { create(:project, user:, created_at: 1.day.ago) }
    let!(:newest) { create(:project, user:, created_at: Time.current) }

    it 'returns projects ordered by newest first with limit' do
      results = query.recent_projects(2)

      expect(results).to eq([newest, newer])
      expect(results).not_to include(older)
    end
  end

  describe '#recent_agreements' do
    let(:other_user) { create(:user) }

    let!(:older_agreement) do
      create(:agreement, :with_participants,
             project: create(:project, user:),
             initiator: user,
             other_party: other_user,
             created_at: 3.days.ago)
    end

    let!(:newer_agreement) do
      create(:agreement, :with_participants,
             project: create(:project, user:),
             initiator: user,
             other_party: other_user,
             created_at: 1.day.ago)
    end

    it 'returns agreements involving the user ordered by newest first' do
      results = query.recent_agreements(1)

      expect(results).to eq([newer_agreement])
      expect(results).not_to include(older_agreement)
    end
  end

  describe '#upcoming_meetings' do
    let(:agreement) do
      create(:agreement, :with_participants,
             project: create(:project, user:),
             initiator: user,
             other_party: create(:user),
             status: Agreement::ACCEPTED)
    end

    let!(:future_meeting) do
      create(:meeting, agreement:, start_time: 2.days.from_now, end_time: 3.days.from_now)
    end

    let!(:sooner_meeting) do
      create(:meeting, agreement:, start_time: 1.day.from_now, end_time: 1.day.from_now + 1.hour)
    end

    let!(:past_meeting) do
      create(:meeting, agreement:, start_time: 2.days.ago, end_time: 2.days.ago + 1.hour)
    end

    it 'returns upcoming meetings ordered soonest first' do
      results = query.upcoming_meetings(2)

      expect(results).to eq([sooner_meeting, future_meeting])
      expect(results).not_to include(past_meeting)
    end
  end

  describe '#mentor_opportunities' do
    let!(:mentor_project) { create(:project, collaboration_type: Project::SEEKING_MENTOR) }
    let!(:both_project) { create(:project, collaboration_type: Project::SEEKING_BOTH) }
    let!(:matched_project) do
      project = create(:project, collaboration_type: Project::SEEKING_MENTOR)
      create(:agreement, :with_participants,
             project:,
             initiator: project.user,
             other_party: user,
             status: Agreement::ACCEPTED)
      project
    end

    it 'returns mentor-seeking projects without existing agreements for the user' do
      results = query.mentor_opportunities

      expect(results).to include(mentor_project, both_project)
      expect(results).not_to include(matched_project)
    end
  end

  describe '#stats' do
    let(:stat_defaults) do
      {
        stale?: false,
        total_projects: 3,
        active_agreements: 1,
        total_agreements: 2,
        completed_agreements: 1,
        pending_agreements: 1,
        agreements_as_initiator: 1,
        agreements_as_participant: 1,
        total_meetings: 4,
        upcoming_meetings: 2,
        total_milestones: 5,
        completed_milestones: 2,
        in_progress_milestones: 1,
        projects_seeking_mentor: 2,
        projects_seeking_cofounder: 1
      }
    end

    before do
      allow(DashboardStat).to receive(:refresh!).and_return(true)
    end

    it 'returns cached stats when they are fresh' do
      stat = instance_double(DashboardStat, stat_defaults)
      allow(DashboardStat).to receive(:for_user).with(user).and_return(stat)

      expect(query.stats).to eq(stat_defaults.except(:stale?))
      expect(DashboardStat).not_to have_received(:refresh!)
    end

    it 'refreshes stale stats' do
      stale_stat = instance_double(DashboardStat, stat_defaults.merge(stale?: true))
      fresh_stat = instance_double(DashboardStat, stat_defaults.merge(total_projects: 7, stale?: false))
      allow(DashboardStat).to receive(:for_user).with(user).and_return(stale_stat, fresh_stat)

      stats = query.stats

      expect(DashboardStat).to have_received(:refresh!)
      expect(stats[:total_projects]).to eq(7)
    end

    it 'returns default stats when none are available' do
      allow(DashboardStat).to receive(:for_user).with(user).and_return(nil, nil)

      expect(query.stats).to eq({
        total_projects: 0,
        active_agreements: 0,
        total_agreements: 0,
        completed_agreements: 0,
        pending_agreements: 0,
        agreements_as_initiator: 0,
        agreements_as_participant: 0,
        total_meetings: 0,
        upcoming_meetings: 0,
        total_milestones: 0,
        completed_milestones: 0,
        in_progress_milestones: 0,
        projects_seeking_mentor: 0,
        projects_seeking_cofounder: 0
      })
    end
  end
end
