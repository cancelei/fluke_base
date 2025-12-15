require 'rails_helper'

RSpec.describe TimeLogsQuery do
  let(:owner) { create(:user) }
  let(:participant) { create(:user) }
  let(:project) { create(:project, user: owner) }
  let(:query_for_owner) { described_class.new(owner) }
  let(:query_for_participant) { described_class.new(participant) }

  before do
    create(:agreement, :with_participants, :mentorship, project: project, initiator: owner, other_party: participant, status: Agreement::ACCEPTED)
  end

  describe '#milestones_for_project' do
    it 'returns all milestones for owner' do
      m1 = create(:milestone, project: project)
      expect(query_for_owner.milestones_for_project(project)).to include(m1)
    end

    it 'returns only agreement milestones for participant' do
      m_allowed = create(:milestone, project: project)
      m_other = create(:milestone, project: project)
      # Only include m_allowed in agreement milestone_ids
      agreement = project.agreements.first
      agreement.update!(milestone_ids: [ m_allowed.id ])

      list = query_for_participant.milestones_for_project(project)
      expect(list).to include(m_allowed)
      expect(list).not_to include(m_other)
    end
  end

  describe '#time_logs_for_project' do
    it 'filters by selected date and orders desc' do
      m = create(:milestone, project: project)
      create(:time_log, project: project, milestone: m, user: owner, started_at: Time.zone.parse('2024-01-01 10:00'))
      today_log = create(:time_log, project: project, milestone: m, user: owner, started_at: 2.hours.ago, ended_at: 1.hour.ago)
      list = query_for_owner.time_logs_for_project(project, Date.current)
      expect(list).to include(today_log)
      expect(list.first.started_at).to be >= list.last.started_at if list.size > 1
    end
  end

  describe '#filtered_time_logs' do
    it 'applies user filter and date' do
      m = create(:milestone, project: project)
      today = Date.current
      a = create(:time_log, project: project, milestone: m, user: owner, started_at: 2.hours.ago, ended_at: 1.hour.ago)
      b = create(:time_log, project: project, milestone: m, user: participant, started_at: 2.hours.ago, ended_at: 1.hour.ago)

      list = query_for_owner.filtered_time_logs(project, owner, today, [ project ], [ m ])
      expect(list).to include(a)
      expect(list).not_to include(b)
    end
  end

  describe '#milestones_pending_confirmation' do
    it 'returns in_progress milestones with completed time_logs' do
      m = create(:milestone, project: project, status: Milestone::IN_PROGRESS)
      create(:time_log, project: project, milestone: m, user: owner, status: 'completed')
      list = query_for_owner.milestones_pending_confirmation(Milestone.where(id: [ m.id ]))
      expect(list).to include(m)
    end
  end

  describe '#time_logs_completed' do
    it 'returns completed milestone logs on selected date' do
      m = create(:milestone, project: project, status: Milestone::COMPLETED)
      create(:time_log, project: project, milestone: m, user: owner, status: 'completed', started_at: Time.zone.now, ended_at: Time.zone.now + 1.hour)
      list = query_for_owner.time_logs_completed(Milestone.where(id: [ m.id ]), Date.current)
      expect(list).to include(m)
    end
  end

  describe '#projects_for_filter' do
    it 'includes owner and mentor projects' do
      other_project = create(:project, user: owner)
      ids = query_for_owner.projects_for_filter.ids
      expect(ids).to include(project.id)
      expect(ids).to include(other_project.id)
    end
  end

  describe '#users_for_filter' do
    it 'returns distinct users who logged time on given milestones' do
      m = create(:milestone, project: project)
      create(:time_log, project: project, milestone: m, user: owner)
      list = query_for_owner.users_for_filter(Milestone.where(id: [ m.id ]))
      expect(list.map(&:id)).to include(owner.id)
    end
  end

  describe '#manual_time_logs' do
    it 'returns manual time logs for current user by default' do
      manual = create(:time_log, project: project, user: owner, milestone: nil, manual_entry: true)
      expect(query_for_owner.manual_time_logs).to include(manual)
    end
  end
end
