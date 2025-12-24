# == Schema Information
#
# Table name: github_branch_logs
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  github_branch_id :bigint           not null
#  github_log_id    :bigint           not null
#
# Indexes
#
#  index_github_branch_logs_on_github_branch_id_and_github_log_id  (github_branch_id,github_log_id) UNIQUE
#  index_github_branch_logs_on_github_log_id                       (github_log_id)
#
# Foreign Keys
#
#  fk_rails_...  (github_branch_id => github_branches.id) ON DELETE => cascade
#  fk_rails_...  (github_log_id => github_logs.id) ON DELETE => cascade
#
require 'rails_helper'

# GithubBranchLog Model Testing - Following patterns from technical_spec/test_spec/ruby_testing/README.md:42-349
# Reference: Comprehensive Model Testing section for association, validation, and business logic patterns

RSpec.describe GithubBranchLog, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }
  let(:github_branch) { create(:github_branch, project:, user:) }
  let(:github_log) { create(:github_log, project:, user:) }
  let(:github_branch_log) { create(:github_branch_log, github_branch:, github_log:) }

  # Association Testing - Line 49-58 in test_spec
  describe "associations" do
    it { should belong_to(:github_branch) }
    it { should belong_to(:github_log) }
  end

  # Validation Testing with Context - Line 60-102 in test_spec
  describe "validations" do
    subject { create(:github_branch_log) }

    it { should validate_presence_of(:github_branch) }
    it { should validate_presence_of(:github_log) }
    it { should validate_uniqueness_of(:github_log_id).scoped_to(:github_branch_id) }
  end

  # Business Logic Testing - Line 129-148 in test_spec
  describe "instance methods" do
    describe "#commit_info" do
      it "returns commit information" do
        info = github_branch_log.commit_info
        expect(info[:sha]).to eq(github_log.commit_sha)
        expect(info[:message]).to eq(github_log.commit_message)
        expect(info[:date]).to eq(github_log.commit_date)
        expect(info[:author]).to eq(github_log.user.full_name)
      end
    end

    describe "#lines_changed" do
      it "returns total lines changed for this commit" do
        github_log.update!(lines_added: 25, lines_removed: 10)
        expect(github_branch_log.lines_changed).to eq(35)
      end
    end

    describe "#branch_name" do
      it "delegates to github_branch" do
        expect(github_branch_log.branch_name).to eq(github_branch.branch_name)
      end
    end
  end

  # Scope Testing - Line 104-126 in test_spec
  describe "scopes" do
    let(:other_branch) { create(:github_branch, project:, user:) }
    let!(:branch_log_1) { create(:github_branch_log, github_branch:) }
    let!(:branch_log_2) { create(:github_branch_log, github_branch: other_branch) }

    describe ".for_branch" do
      it "returns logs for specific branch" do
        expect(GithubBranchLog.for_branch(github_branch)).to include(branch_log_1)
        expect(GithubBranchLog.for_branch(github_branch)).not_to include(branch_log_2)
      end
    end

    describe ".recent" do
      it "orders by commit date" do
        old_log = create(:github_log)
        new_log = create(:github_log)

        # Explicitly set commit dates after creation to ensure ordering
        old_log.update!(commit_date: 2.days.ago)
        new_log.update!(commit_date: 1.day.ago)

        old_branch_log = create(:github_branch_log, github_log: old_log)
        new_branch_log = create(:github_branch_log, github_log: new_log)

        # Get only the branch logs we created and verify ordering
        created_logs = GithubBranchLog.where(id: [old_branch_log.id, new_branch_log.id]).recent
        expect(created_logs.first.github_log).to eq(new_log)
        expect(created_logs.last.github_log).to eq(old_log)
      end
    end
  end

  # Factory Integration Testing - Line 507-549 in test_spec
  describe "factory integration" do
    it "creates valid github branch log with factory" do
      branch_log = create(:github_branch_log)
      expect(branch_log).to be_valid
      expect(branch_log.github_branch).to be_present
      expect(branch_log.github_log).to be_present
    end
  end
end
