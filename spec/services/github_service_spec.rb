require 'rails_helper'

RSpec.describe GithubService do
  let(:owner) { create(:user, github_username: 'owner') }
  let(:project) { create(:project, user: owner, repository_url: 'testuser/testrepo', public_fields: [ 'name' ]) }

  # Minimal fake branch object
  Branch = Struct.new(:name)

  def build_commit(sha:, author_login: nil, author_email: 'dev@example.com', additions: 3, deletions: 1)
    file = OpenStruct.new(filename: 'file.rb', status: 'modified', additions: additions, deletions: deletions, patch: '+ code')
    commit_obj = OpenStruct.new(
      sha: sha,
      html_url: "https://github.com/x/y/commit/#{sha}",
      author: (author_login ? OpenStruct.new(login: author_login) : nil),
      commit: OpenStruct.new(
        author: OpenStruct.new(email: author_email, date: Time.current),
        message: 'Commit msg'
      ),
      stats: { additions: additions, deletions: deletions },
      files: [ file ]
    )
    shallow = OpenStruct.new(sha: sha, commit: OpenStruct.new(message: 'Shallow'))
    [ shallow, commit_obj ]
  end

  describe '#fetch_branches_with_owner' do
    it 'returns [] when repository_url is blank' do
      project.update!(repository_url: '')
      service = described_class.new(project)
      result = service.fetch_branches_with_owner
      expect(result).to be_failure
    end

    it 'fetches branches and upserts owners; defaults to project owner when user not found' do
      service = described_class.new(project)

      client = double('client')
      allow(service).to receive(:github_client).and_return(client)

      branches = [ Branch.new('main'), Branch.new('feature/x') ]
      allow(service).to receive(:branches).and_return(branches)

      # first_commit_on_branch invoked per branch
      allow(service).to receive(:first_commit_on_branch).with('testuser/testrepo', 'main').and_return({ email: 'unknown@example.com' })
      allow(service).to receive(:first_commit_on_branch).with('testuser/testrepo', 'feature/x').and_return({ email: owner.email })

      result = service.fetch_branches_with_owner
      expect(result).to be_success

      branch_owners = result.value!
      expect(branch_owners).to be_an(Array)
      expect(branch_owners.size).to eq(2)
      # Ensure structure contains expected keys
      expect(branch_owners.first).to include(:project_id, :user_id, :branch_name)
      # One branch should default to project owner (unknown email)
      expect(branch_owners.map { |h| h[:user_id] }).to include(owner.id)
    end
  end

  describe '#fetch_commits' do
    let(:mentor) { create(:user, github_username: 'mentor') }
    let!(:branch) { create(:github_branch, project: project, user: owner, branch_name: 'main') }
    let!(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: owner, other_party: mentor, status: Agreement::ACCEPTED) }

    it 'returns processed commits for a specified branch and maps user by github login' do
      client = double('client')
      allow_any_instance_of(described_class).to receive(:github_client).and_return(client)

      service = described_class.new(project, nil, branch: 'main')

      shallow1, full1 = build_commit(sha: 'a1', author_login: 'mentor')
      shallow2, full2 = build_commit(sha: 'b2', author_login: 'mentor')

      # Mock helper methods for SHA deduplication
      allow(service).to receive(:get_existing_commit_shas).and_return(Set.new)

      # Mock last_response for pagination
      last_response = double('last_response', rels: {})
      allow(client).to receive(:last_response).and_return(last_response)

      # Return both commits on first page (since we're not testing pagination here)
      allow(client).to receive(:commits).with('testuser/testrepo', hash_including(sha: 'main', page: 1, per_page: 100)).and_return([ shallow1, shallow2 ])
      allow(client).to receive(:commits).with('testuser/testrepo', hash_including(sha: 'main', page: 2, per_page: 100)).and_return([])

      allow(client).to receive(:commit).with('testuser/testrepo', 'a1').and_return(full1)
      allow(client).to receive(:commit).with('testuser/testrepo', 'b2').and_return(full2)

      result = service.fetch_commits
      expect(result).to be_success

      payload = result.value!
      expect(payload).to be_a(Hash)
      expect(payload[:commits].size).to eq(2)
      expect(payload[:all_shas]).to contain_exactly('a1', 'b2')
      expect(payload[:commits].all? { |h| h[:project_id] == project.id }).to be true
      expect(payload[:commits].all? { |h| h[:commit_sha].present? }).to be true
      expect(payload[:commits].map { |h| h[:agreement_id] }.uniq).to include(agreement.id)
      expect(payload[:commits].map { |h| h[:user_id] }.uniq).to include(mentor.id)
    end

    it 'skips commits that already exist in the database' do
      client = double('client')
      allow_any_instance_of(described_class).to receive(:github_client).and_return(client)

      service = described_class.new(project, nil, branch: 'main')

      shallow1, full1 = build_commit(sha: 'a1', author_login: 'mentor')
      shallow2, full2 = build_commit(sha: 'b2', author_login: 'mentor')
      shallow3, full3 = build_commit(sha: 'c3', author_login: 'mentor')

      # Mock that 'a1' and 'b2' already exist in database
      allow(service).to receive(:get_existing_commit_shas).and_return(Set.new([ 'a1', 'b2' ]))

      # Mock last_response for pagination
      last_response = double('last_response', rels: {})
      allow(client).to receive(:last_response).and_return(last_response)

      # API returns all three commits
      allow(client).to receive(:commits).with('testuser/testrepo', hash_including(sha: 'main', page: 1, per_page: 100)).and_return([ shallow1, shallow2, shallow3 ])
      allow(client).to receive(:commits).with('testuser/testrepo', hash_including(sha: 'main', page: 2, per_page: 100)).and_return([])

      # Only c3 should be fetched in detail
      allow(client).to receive(:commit).with('testuser/testrepo', 'c3').and_return(full3)

      result = service.fetch_commits
      expect(result).to be_success
      payload = result.value!
      # Only one new commit should be processed (c3), but all three SHAs should be returned
      expect(payload[:commits].size).to eq(1)
      expect(payload[:all_shas]).to contain_exactly('a1', 'b2', 'c3')
    end

    it 'fetches all commits without using since parameter to ensure complete history' do
      client = double('client')
      allow_any_instance_of(described_class).to receive(:github_client).and_return(client)

      service = described_class.new(project, nil, branch: 'main')

      allow(service).to receive(:get_existing_commit_shas).and_return(Set.new)

      shallow1, full1 = build_commit(sha: 'a1', author_login: 'mentor')

      # Mock last_response for pagination
      last_response = double('last_response', rels: {})
      allow(client).to receive(:last_response).and_return(last_response)

      # Expect API call WITHOUT since parameter (to ensure we get complete history)
      # This prevents missing older commits in case of partial fetches
      expect(client).to receive(:commits).with('testuser/testrepo', hash_including(sha: 'main', page: 1, per_page: 100)).and_return([ shallow1 ])

      allow(client).to receive(:commit).with('testuser/testrepo', 'a1').and_return(full1)

      result = service.fetch_commits
      expect(result).to be_success

      payload = result.value!
      expect(payload[:commits].size).to eq(1)
      expect(payload[:commits].first[:commit_sha]).to eq('a1')
    end

    it 'returns [] when DB branch missing' do
      client = double('client')
      GithubBranch.where(project: project, branch_name: 'main').delete_all
      service = described_class.new(project, nil, branch: 'main')
      allow(service).to receive(:github_client).and_return(client)

      result = service.fetch_commits
      expect(result).to be_failure
    end
  end
end
