require 'rails_helper'

RSpec.describe ProjectGithubService do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:project) { create(:project, user: owner) }
  let(:service) { described_class.new(project) }

  describe '#connected?' do
    it 'is false when repository_url is blank' do
      project.update!(repository_url: nil)
      expect(service.connected?).to be false
    end

    it 'is true when repository_url is present' do
      project.update!(repository_url: 'https://github.com/acme/repo')
      expect(service.connected?).to be true
    end
  end

  describe '#available_branches' do
    it 'returns sorted [id, branch_name] pairs' do
      b1 = create(:github_branch, project:, branch_name: 'feature/x')
      b2 = create(:github_branch, project:, branch_name: 'main')

      expect(service.available_branches).to eq([[b1.id, 'feature/x'], [b2.id, 'main']].sort)
    end
  end

  describe '#recent_logs' do
    it 'returns logs ordered by most recent first and limited' do
      older = create(:github_log, project:, user: owner, commit_date: 3.days.ago)
      middle = create(:github_log, project:, user: owner, commit_date: 2.days.ago)
      newest = create(:github_log, project:, user: owner, commit_date: 1.day.ago)

      expect(service.recent_logs(2)).to eq([newest, middle])
      expect(service.recent_logs).to include(newest, middle, older)
    end
  end

  describe '#contributions_summary' do
    let!(:branch_a) { create(:github_branch, project:, user: owner, branch_name: 'main') }
    let!(:branch_b) { create(:github_branch, project:, user: owner, branch_name: 'feature/one') }

    def log_for(user:, branch:, commits: 1, added: 1, removed: 0, unregistered_name: nil)
      commits.times do
        if user.nil?
          log = create(:github_log, :unregistered,
                       project:,
                       unregistered_user_name: unregistered_name,
                       lines_added: added,
                       lines_removed: removed,
                       commit_date: Time.current)
        else
          log = create(:github_log, :with_user,
                       project:,
                       user:,
                       unregistered_user_name: unregistered_name,
                       lines_added: added,
                       lines_removed: removed,
                       commit_date: Time.current)
        end
        create(:github_branch_log, github_branch: branch, github_log: log)
      end
    end

    it 'combines registered and unregistered contributions and sorts by commit_count desc' do
      # Registered user with 2 commits
      log_for(user: owner, branch: branch_a, commits: 2, added: 3, removed: 1)
      # Unregistered user with 1 commit
      log_for(user: nil, branch: branch_a, commits: 1, added: 10, removed: 0, unregistered_name: 'bot')

      summary = service.contributions_summary

      # Registered contribution row
      registered = summary.find { |r| r.respond_to?(:user_id) && r.user_id == owner.id }
      expect(registered.commit_count.to_i).to eq(2)
      expect(registered.total_added.to_i).to be >= 6

      # Unregistered contribution row
      unregistered = summary.find { |r| r.respond_to?(:unregistered_user_name) && r.unregistered_user_name == 'bot' }
      expect(unregistered.commit_count.to_i).to eq(1)

      # Sorted: registered (2 commits) should come before unregistered (1)
      expect(summary.index(registered)).to be < summary.index(unregistered)
    end

    it 'filters by branch when provided' do
      # Owner commits to both branches
      log_for(user: owner, branch: branch_a, commits: 2)
      log_for(user: owner, branch: branch_b, commits: 1)

      summary_main = service.contributions_summary(branch_a.id)
      row = summary_main.find { |r| r.respond_to?(:user_id) && r.user_id == owner.id }
      expect(row.commit_count.to_i).to eq(2)
    end
  end

  describe '#can_view_logs? and #can_access_repository?' do
    it 'allows project owner' do
      expect(service.can_view_logs?(owner)).to be true
      expect(service.can_access_repository?(owner)).to be true
    end

    it 'allows active agreement participant and denies unrelated users' do
      stranger = other_user
      expect(service.can_view_logs?(stranger)).to be false

      # Create active agreement with other_user as participant
      agreement = create(:agreement, :with_participants, :mentorship,
                         project:, initiator: owner, other_party: other_user,
                         status: Agreement::ACCEPTED)
      expect(service.can_view_logs?(other_user)).to be true
    end
  end
end
