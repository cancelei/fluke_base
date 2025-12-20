require 'rails_helper'

RSpec.describe 'GithubService multi-branch optimization' do
  let(:owner) { create(:user, github_username: 'owner') }
  let(:project) { create(:project, user: owner, repository_url: 'testuser/testrepo') }

  def build_commit(sha:, author_login: nil, author_email: 'dev@example.com')
    file = OpenStruct.new(filename: 'file.rb', status: 'modified', additions: 10, deletions: 5, patch: '+ code')
    commit_obj = OpenStruct.new(
      sha:,
      html_url: "https://github.com/x/y/commit/#{sha}",
      author: (author_login ? OpenStruct.new(login: author_login) : nil),
      commit: OpenStruct.new(
        author: OpenStruct.new(email: author_email, date: Time.current),
        message: "Commit #{sha}"
      ),
      stats: { additions: 10, deletions: 5 },
      files: [file]
    )
    shallow = OpenStruct.new(sha:, commit: OpenStruct.new(message: "Commit #{sha}"))
    [shallow, commit_obj]
  end

  describe 'fetching commits from multiple branches' do
    it 'checks for existing commits globally across all branches' do
      # Create commits in database for one branch
      GithubBranch.create!(project:, user: owner, branch_name: 'main')
      GithubBranch.create!(project:, user: owner, branch_name: 'develop')

      # Create some commits
      commits = [
        {
          project_id: project.id,
          commit_sha: 'sha1',
          commit_message: 'Commit 1',
          lines_added: 10,
          lines_removed: 5,
          commit_date: 3.days.ago,
          commit_url: 'https://github.com/test/1',
          unregistered_user_name: 'dev1'
        },
        {
          project_id: project.id,
          commit_sha: 'sha2',
          commit_message: 'Commit 2',
          lines_added: 20,
          lines_removed: 10,
          commit_date: 2.days.ago,
          commit_url: 'https://github.com/test/2',
          unregistered_user_name: 'dev2'
        }
      ]

      GithubLog.upsert_all(commits, unique_by: :commit_sha)

      # Now check what get_existing_commit_shas returns
      service = GithubService.new(project, nil, branch: 'develop')
      existing_shas = service.send(:get_existing_commit_shas)

      # Should return commits from ALL branches in the project, not just develop
      expect(existing_shas).to be_a(Set)
      expect(existing_shas.size).to eq(2)
      expect(existing_shas).to include('sha1', 'sha2')

      puts "\n✓ Optimization confirmed: get_existing_commit_shas checks globally across all branches"
      puts "  This prevents re-fetching commits that exist in other branches"
      puts "  Existing SHAs found: #{existing_shas.to_a.join(', ')}"
    end

    it 'returns all commit SHAs including existing ones for branch associations' do
      # Setup: main branch already has commits A and B
      GithubBranch.create!(project:, user: owner, branch_name: 'main')
      GithubBranch.create!(project:, user: owner, branch_name: 'develop')

      # Store commits A and B (from main branch)
      existing_commits = [
        {
          project_id: project.id,
          commit_sha: 'commit_a',
          commit_message: 'Commit A',
          lines_added: 10,
          lines_removed: 5,
          commit_date: 3.days.ago,
          commit_url: 'https://github.com/test/a',
          unregistered_user_name: 'dev1'
        },
        {
          project_id: project.id,
          commit_sha: 'commit_b',
          commit_message: 'Commit B',
          lines_added: 20,
          lines_removed: 10,
          commit_date: 2.days.ago,
          commit_url: 'https://github.com/test/b',
          unregistered_user_name: 'dev2'
        }
      ]
      GithubLog.upsert_all(existing_commits, unique_by: :commit_sha)

      # Mock GitHub API to return commits A, B, C for develop branch
      shallow_a, _ = build_commit(sha: 'commit_a', author_login: 'dev1')
      shallow_b, _ = build_commit(sha: 'commit_b', author_login: 'dev2')
      shallow_c, full_c = build_commit(sha: 'commit_c', author_login: 'dev1')

      client = double('client')
      allow_any_instance_of(GithubService).to receive(:github_client).and_return(client)

      # Mock last_response for pagination
      last_response = double('last_response', rels: {})
      allow(client).to receive(:last_response).and_return(last_response)

      # API returns all three commits
      allow(client).to receive(:commits).with('testuser/testrepo', hash_including(sha: 'develop', page: 1)).and_return([shallow_a, shallow_b, shallow_c])
      allow(client).to receive(:commits).with('testuser/testrepo', hash_including(sha: 'develop', page: 2)).and_return([])

      # Only commit C needs full details
      allow(client).to receive(:commit).with('testuser/testrepo', 'commit_c').and_return(full_c)

      service = GithubService.new(project, nil, branch: 'develop')
      result = service.fetch_commits

      # Verify the result
      expect(result).to be_a(Dry::Monads::Result)
      expect(result).to be_success

      payload = result.value!
      expect(payload[:commits].size).to eq(1) # Only new commit C
      expect(payload[:commits].first[:commit_sha]).to eq('commit_c')
      expect(payload[:all_shas]).to contain_exactly('commit_a', 'commit_b', 'commit_c') # All commits in branch

      puts "\n✓ Service correctly returns:"
      puts "  - New commits for storage: #{payload[:commits].map { |c| c[:commit_sha] }.join(', ')}"
      puts "  - All SHAs for branch associations: #{payload[:all_shas].join(', ')}"
      puts "  This allows job to associate ALL commits with the branch, not just new ones"
    end
  end
end
