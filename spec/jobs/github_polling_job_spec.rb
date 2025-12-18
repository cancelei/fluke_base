# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubPollingJob, type: :job do
  describe "#perform" do
    let(:user_with_token) { create(:user, github_token: "valid_token_123") }
    let(:user_without_token) { create(:user, github_token: nil) }

    let!(:project_with_repo) do
      create(:project,
             user: user_with_token,
             repository_url: "https://github.com/org/repo")
    end

    let!(:branch) do
      create(:github_branch,
             project: project_with_repo,
             user: user_with_token,
             branch_name: "main")
    end

    it "enqueues commit refresh jobs for eligible projects" do
      expect {
        described_class.perform_now
      }.to have_enqueued_job(GithubCommitRefreshJob)
        .with(project_with_repo.id, "valid_token_123", "main")
    end

    it "skips projects without github tokens" do
      project_no_token = create(:project,
                                user: user_without_token,
                                repository_url: "https://github.com/org/repo2")
      create(:github_branch, project: project_no_token, user: user_without_token, branch_name: "main")

      described_class.perform_now

      # Should not enqueue for project without token
      expect(GithubCommitRefreshJob).not_to have_been_enqueued
        .with(project_no_token.id, anything, anything)
    end

    it "skips projects without repository_url" do
      project_no_repo = create(:project,
                               user: user_with_token,
                               repository_url: nil)

      described_class.perform_now

      expect(GithubCommitRefreshJob).not_to have_been_enqueued
        .with(project_no_repo.id, anything, anything)
    end

    it "skips projects without branches" do
      project_no_branches = create(:project,
                                   user: user_with_token,
                                   repository_url: "https://github.com/org/another-repo")
      # No branch created for this project

      described_class.perform_now

      expect(GithubCommitRefreshJob).not_to have_been_enqueued
        .with(project_no_branches.id, anything, anything)
    end

    it "skips projects polled within the last 50 seconds" do
      project_with_repo.update_column(:github_last_polled_at, 30.seconds.ago)

      expect {
        described_class.perform_now
      }.not_to have_enqueued_job(GithubCommitRefreshJob)
        .with(project_with_repo.id, anything, anything)
    end

    it "polls projects that were polled more than 50 seconds ago" do
      project_with_repo.update_column(:github_last_polled_at, 60.seconds.ago)

      expect {
        described_class.perform_now
      }.to have_enqueued_job(GithubCommitRefreshJob)
        .with(project_with_repo.id, "valid_token_123", "main")
    end

    it "polls projects that have never been polled" do
      project_with_repo.update_column(:github_last_polled_at, nil)

      expect {
        described_class.perform_now
      }.to have_enqueued_job(GithubCommitRefreshJob)
        .with(project_with_repo.id, "valid_token_123", "main")
    end

    it "updates github_last_polled_at timestamp" do
      expect {
        described_class.perform_now
      }.to change { project_with_repo.reload.github_last_polled_at }.from(nil)

      expect(project_with_repo.github_last_polled_at).to be_within(5.seconds).of(Time.current)
    end

    it "limits to 3 branches per project" do
      # Create additional branches
      create(:github_branch, project: project_with_repo, user: user_with_token, branch_name: "develop")
      create(:github_branch, project: project_with_repo, user: user_with_token, branch_name: "feature/a")
      create(:github_branch, project: project_with_repo, user: user_with_token, branch_name: "feature/b")

      expect {
        described_class.perform_now
      }.to have_enqueued_job(GithubCommitRefreshJob).exactly(3).times
    end

    it "handles errors gracefully without stopping other projects" do
      other_project = create(:project,
                             user: user_with_token,
                             repository_url: "https://github.com/org/other")
      create(:github_branch, project: other_project, user: user_with_token, branch_name: "main")

      allow_any_instance_of(Project).to receive(:github_branches)
        .and_wrap_original do |method, *args|
          if method.receiver.id == project_with_repo.id
            raise StandardError, "Simulated error"
          else
            method.call(*args)
          end
        end

      # Should not raise and should still enqueue for other project
      expect {
        described_class.perform_now
      }.to have_enqueued_job(GithubCommitRefreshJob)
        .with(other_project.id, "valid_token_123", "main")
    end
  end
end
