# == Schema Information
#
# Table name: github_branches
#
#  id          :bigint           not null, primary key
#  branch_name :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  project_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  idx_on_project_id_branch_name_user_id_fcdce7d2d8  (project_id,branch_name,user_id) UNIQUE
#  index_github_branches_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

# GithubBranch Model Testing - Following patterns from technical_spec/test_spec/ruby_testing/README.md:42-349
# Reference: Comprehensive Model Testing section for association, validation, and business logic patterns

RSpec.describe GithubBranch, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }
  let(:github_branch) { create(:github_branch, project:, user:) }

  # Association Testing - Line 49-58 in test_spec
  describe "associations" do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
    it { should have_many(:github_branch_logs).dependent(:destroy) }
    it { should have_many(:github_logs).through(:github_branch_logs) }
  end

  # Validation Testing with Context - Line 60-102 in test_spec
  describe "validations" do
    subject { create(:github_branch) }

    it { should validate_presence_of(:branch_name) }
    # Project and User presence validations are tested by belongs_to matchers in associations section

    it { should validate_uniqueness_of(:branch_name).scoped_to([:project_id, :user_id]) }
    it { should validate_length_of(:branch_name).is_at_most(255) }

    context "branch name format" do
      it "accepts valid branch names" do
        valid_names = %w[main develop feature/user-auth hotfix/critical-bug]
        valid_names.each do |name|
          branch = build(:github_branch, branch_name: name)
          expect(branch).to be_valid
        end
      end

      it "rejects invalid branch names" do
        invalid_names = ['', ' ', 'branch with spaces', 'branch..name']
        invalid_names.each do |name|
          branch = build(:github_branch, branch_name: name)
          expect(branch).not_to be_valid
        end
      end
    end
  end

  # Business Logic Testing - Line 129-148 in test_spec
  describe "instance methods" do
    describe "#commit_count" do
      it "returns number of commits on branch" do
        create_list(:github_log, 3, project:, user:).each do |log|
          create(:github_branch_log, github_branch:, github_log: log)
        end

        expect(github_branch.commit_count).to eq(3)
      end
    end

    describe "#latest_commit" do
      it "returns most recent commit on branch" do
        old_commit = create(:github_log, project:, user:, commit_date: 2.days.ago)
        new_commit = create(:github_log, project:, user:, commit_date: 1.day.ago)

        create(:github_branch_log, github_branch:, github_log: old_commit)
        create(:github_branch_log, github_branch:, github_log: new_commit)

        expect(github_branch.latest_commit).to eq(new_commit)
      end
    end

    describe "#total_lines_changed" do
      it "returns sum of lines added and removed" do
        commit1 = create(:github_log, project:, user:, lines_added: 50, lines_removed: 10)
        commit2 = create(:github_log, project:, user:, lines_added: 30, lines_removed: 5)

        create(:github_branch_log, github_branch:, github_log: commit1)
        create(:github_branch_log, github_branch:, github_log: commit2)

        expect(github_branch.total_lines_changed).to eq(95) # (50+10) + (30+5)
      end
    end

    describe "#branch_type" do
      it "identifies feature branches" do
        branch = build(:github_branch, branch_name: "feature/user-auth")
        expect(branch.branch_type).to eq("feature")
      end

      it "identifies hotfix branches" do
        branch = build(:github_branch, branch_name: "hotfix/critical-bug")
        expect(branch.branch_type).to eq("hotfix")
      end

      it "identifies main branches" do
        branch = build(:github_branch, branch_name: "main")
        expect(branch.branch_type).to eq("main")
      end

      it "returns unknown for unrecognized patterns" do
        branch = build(:github_branch, branch_name: "random-branch-name")
        expect(branch.branch_type).to eq("unknown")
      end
    end
  end

  # Scope Testing - Line 104-126 in test_spec
  describe "scopes" do
    let!(:main_branch) { create(:github_branch, branch_name: "main") }
    let!(:feature_branch) { create(:github_branch, branch_name: "feature/new-ui") }
    let!(:user_branch) { create(:github_branch, user:) }
    let!(:other_user_branch) { create(:github_branch, user: create(:user)) }

    describe ".for_project" do
      it "returns branches for specific project" do
        expect(GithubBranch.for_project(project)).to include(github_branch)
      end
    end

    describe ".for_user" do
      it "returns branches for specific user" do
        expect(GithubBranch.for_user(user)).to include(user_branch)
        expect(GithubBranch.for_user(user)).not_to include(other_user_branch)
      end
    end

    describe ".by_type" do
      it "filters branches by type" do
        expect(GithubBranch.by_type("main")).to include(main_branch)
        expect(GithubBranch.by_type("feature")).to include(feature_branch)
      end
    end

    describe ".recent" do
      it "orders branches by creation date" do
        old_branch = create(:github_branch)
        new_branch = create(:github_branch)

        # Explicitly set created_at timestamps after creation
        old_branch.update!(created_at: 1.week.ago)
        new_branch.update!(created_at: 1.day.ago)

        # Get only the branches we created and verify ordering
        created_branches = GithubBranch.where(id: [old_branch.id, new_branch.id]).recent
        expect(created_branches.first).to eq(new_branch)
        expect(created_branches.last).to eq(old_branch)
      end
    end
  end

  # Factory Integration Testing - Line 507-549 in test_spec
  describe "factory integration" do
    it "creates valid github branch with factory" do
      branch = create(:github_branch)
      expect(branch).to be_valid
      expect(branch.branch_name).to be_present
      expect(branch.project).to be_present
      expect(branch.user).to be_present
    end
  end
end
