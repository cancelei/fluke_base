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
      expect(service.fetch_branches_with_owner).to eq([])
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
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      # Ensure structure contains expected keys
      expect(result.first).to include(:project_id, :user_id, :branch_name)
      # One branch should default to project owner (unknown email)
      expect(result.map { |h| h[:user_id] }).to include(owner.id)
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

      # Paginated commits: two pages, then empty
      # Mock to return 100 commits on page 1 to force pagination, then 1 on page 2
      allow(client).to receive(:commits).with('testuser/testrepo', hash_including(sha: 'main', page: 1, per_page: 100)).and_return([ shallow1 ])
      allow(client).to receive(:commits).with('testuser/testrepo', hash_including(sha: 'main', page: 2, per_page: 100)).and_return([ shallow2 ])
      allow(client).to receive(:commits).with('testuser/testrepo', hash_including(sha: 'main', page: 3, per_page: 100)).and_return([])

      allow(client).to receive(:commit).with('testuser/testrepo', 'a1').and_return(full1)
      allow(client).to receive(:commit).with('testuser/testrepo', 'b2').and_return(full2)

      result = service.fetch_commits
      expect(result.size).to eq(1)
      expect(result.all? { |h| h[:project_id] == project.id }).to be true
      expect(result.all? { |h| h[:commit_sha].present? }).to be true
      expect(result.map { |h| h[:agreement_id] }.uniq).to include(agreement.id)
      expect(result.map { |h| h[:user_id] }.uniq).to include(mentor.id)
    end

    it 'returns [] when DB branch missing' do
      GithubBranch.where(project: project, branch_name: 'main').delete_all
      service = described_class.new(project, nil, branch: 'main')
      client = double('client', commits: [])
      allow(service).to receive(:github_client).and_return(client)
      expect(service.fetch_commits).to eq([])
    end
  end
end
