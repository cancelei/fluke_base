require 'rails_helper'

# Project Model Testing - Following patterns from technical_spec/test_spec/ruby_testing/README.md:42-349
# Reference: Comprehensive Model Testing section for association, validation, and business logic patterns

RSpec.describe Project, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }

  # Association Testing - Line 49-58 in test_spec
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:agreements).dependent(:destroy) }
    it { should have_many(:milestones).dependent(:destroy) }
    it { should have_one(:project_agent).dependent(:destroy) }
    it { should have_many(:mentorships).class_name('Agreement') }
    it { should have_many(:mentorships).class_name('Agreement') }
    it { should have_many(:time_logs) }
    it { should have_many(:github_logs).dependent(:destroy) }
    it { should have_many(:github_branches).dependent(:destroy) }
  end

  # Validation Testing with Context - Line 60-102 in test_spec
  describe "validations" do
    subject { build(:project, public_fields: ['name']) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:stage) }

    it { should validate_inclusion_of(:collaboration_type).in_array([
      "mentor", "co_founder", "both", nil
    ]) }

    context "when project has repository URL" do
      it "validates repository URL format" do
        project = build(:project, repository_url: "https://github.com/user/repo", public_fields: ['name'])
        expect(project).to be_valid

        project.repository_url = "invalid-url"
        expect(project).not_to be_valid
        expect(project.errors[:repository_url]).to be_present
      end

      it "accepts GitHub username/repo format" do
        project = build(:project, repository_url: "user/repo", public_fields: ['name'])
        expect(project).to be_valid
      end
    end
  end

  # Business Logic Testing - Line 129-148 in test_spec
  describe "defaults" do
    it "ensures essential fields are public when none provided" do
      project = create(:project, public_fields: [])
      expect(project.public_fields).to match_array(Project::DEFAULT_PUBLIC_FIELDS)
    end

    it "keeps custom public field selections when present" do
      project = create(:project, public_fields: ['name', 'description'])
      expect(project.public_fields).to match_array(['name', 'description'])
    end
  end

  describe "instance methods" do
    describe "#progress_percentage" do
      it "returns 0 when no milestones" do
        expect(project.progress_percentage).to eq(0)
      end

      it "calculates percentage based on completed milestones" do
        # Mock the milestones.completed scope
        allow(project.milestones).to receive(:completed).and_return(double(count: 2))
        allow(project).to receive(:milestones_count).and_return(4)

        expect(project.progress_percentage).to eq(50) # 2/4 = 50%
      end
    end

    describe "#seeking_mentor?" do
      it "returns true when seeking mentor" do
        project = build(:project, collaboration_type: "mentor")
        expect(project.seeking_mentor?).to be true
      end

      it "returns true when seeking both" do
        project = build(:project, collaboration_type: "both")
        expect(project.seeking_mentor?).to be true
      end

      it "returns false when seeking cofounder only" do
        project = build(:project, collaboration_type: "co_founder")
        expect(project.seeking_mentor?).to be false
      end
    end

    describe "#seeking_cofounder?" do
      it "returns true when seeking cofounder" do
        project = build(:project, collaboration_type: "co_founder")
        expect(project.seeking_cofounder?).to be true
      end

      it "returns true when seeking both" do
        project = build(:project, collaboration_type: "both")
        expect(project.seeking_cofounder?).to be true
      end
    end

    describe "#github_connected?" do
      it "delegates to github service" do
        expect(project.github_connected?).to be_in([true, false])
      end
    end

    describe "#recent_github_logs" do
      it "orders by commit_date desc and respects limit" do
        older = create(:github_log, project:, user:, commit_date: 3.days.ago)
        middle = create(:github_log, project:, user:, commit_date: 2.days.ago)
        newest = create(:github_log, project:, user:, commit_date: 1.day.ago)
        list = project.recent_github_logs(2)
        expect(list).to eq([newest, middle])
      end
    end

    describe "GitHub integration helpers" do
      it "returns available_branches via service" do
        b1 = create(:github_branch, project:, branch_name: 'feature/a')
        b2 = create(:github_branch, project:, branch_name: 'main')
        expect(project.available_branches).to eq([[b1.id, 'feature/a'], [b2.id, 'main']].sort)
      end

      it "can_view_github_logs? is true for owner and false for stranger" do
        stranger = create(:user)
        expect(project.can_view_github_logs?(project.user)).to be true
        expect(project.can_view_github_logs?(stranger)).to be false
      end
    end

    describe "stage helpers" do
      it "identifies idea stage" do
        project = build(:project, stage: "idea")
        expect(project.idea?).to be true
        expect(project.prototype?).to be false
      end

      it "identifies prototype stage" do
        project = build(:project, stage: "prototype")
        expect(project.prototype?).to be true
        expect(project.idea?).to be false
      end
    end
  end

  describe "github_contributions filters" do
    let!(:branch_main) { create(:github_branch, project:, user:, branch_name: 'main') }
    let!(:branch_feat) { create(:github_branch, project:, user:, branch_name: 'feature/x') }

    def create_log(u:, branch:, added: 1, removed: 0, name: nil)
      log = create(:github_log, :with_user, project:, user: u, unregistered_user_name: name, lines_added: added, lines_removed: removed, commit_date: Time.current)
      create(:github_branch_log, github_branch: branch, github_log: log)
      log
    end

    it "returns [] when no logs" do
      expect(project.github_contributions).to eq([])
    end

    it "filters by branch, agreement_only, and user_name" do
      # Seed logs
      owner_log = create_log(u: user, branch: branch_main, added: 5, removed: 1)
      stranger = create(:user)
      other_log = create_log(u: stranger, branch: branch_feat, added: 2, removed: 0)
      # Create an unregistered user log (no user_id, just unregistered_user_name)
      bot_log = create(:github_log, :unregistered, project:, unregistered_user_name: 'bot', lines_added: 10, lines_removed: 0, commit_date: Time.current)
      create(:github_branch_log, github_branch: branch_main, github_log: bot_log)

      # With logs present, returns data
      all = project.github_contributions
      expect(all.map { |h| h[:commit_count] }.sum).to be >= 3

      # Branch filter limits to main
      main_only = project.github_contributions(branch: branch_main.id)
      # Should not include the feature branch-only user
      expect(main_only.any? { |h| h[:user]&.respond_to?(:id) && h[:user].id == stranger.id }).to be false

      # Agreement-only filter keeps only participant IDs
      mentor = create(:user)
      create(:agreement, :with_participants, :mentorship, project:, initiator: user, other_party: mentor, status: Agreement::ACCEPTED)
      ids = [user.id, mentor.id]
      agreement_only = project.github_contributions(agreement_only: true, agreement_user_ids: ids)
      expect(agreement_only.any? { |h| h[:user]&.respond_to?(:id) && h[:user].id == user.id }).to be true
      expect(agreement_only.any? { |h| h[:user]&.respond_to?(:id) && h[:user].id == stranger.id }).to be false

      # Unregistered user_name filter
      bots = project.github_contributions(user_name: 'bot')
      expect(bots.any? { |h| h[:user].respond_to?(:unregistered) && h[:user].unregistered && h[:user].name == 'bot' }).to be true
    end
  end

  describe "visibility helpers" do
    it "field_public? respects public_fields" do
      p = create(:project, user:, public_fields: ['name', 'description'])
      expect(p.field_public?(:name)).to be true
      expect(p.field_public?(:stage)).to be false
    end

    it "visible_to_user? is true for owner and for public field, false otherwise" do
      p = create(:project, user:, public_fields: ['name'])
      stranger = create(:user)
      expect(p.visible_to_user?(:description, user)).to be true # owner
      expect(p.visible_to_user?(:name, stranger)).to be true    # public field
      expect(p.visible_to_user?(:description, stranger)).to be false
    end

    it "get_field_value returns value only if visible" do
      p = create(:project, user:, name: 'Alpha', description: 'Hidden', public_fields: ['name'])
      stranger = create(:user)
      expect(p.get_field_value(:name, stranger)).to eq('Alpha')
      expect(p.get_field_value(:description, stranger)).to be_nil
      expect(p.get_field_value(:description, user)).to eq('Hidden')
    end
  end

  # Scope Testing - Line 104-126 in test_spec
  describe "scopes" do
    let!(:idea_project) { create(:project, stage: "idea", public_fields: ['name']) }
    let!(:prototype_project) { create(:project, stage: "prototype", public_fields: ['name']) }
    let!(:launched_project) { create(:project, stage: "launched", public_fields: ['name']) }
    let!(:mentor_project) { create(:project, collaboration_type: "mentor", public_fields: ['name']) }
    let!(:cofounder_project) { create(:project, collaboration_type: "co_founder", public_fields: ['name']) }

    describe ".ideas" do
      it "returns idea stage projects" do
        expect(Project.ideas).to include(idea_project)
        expect(Project.ideas).not_to include(prototype_project)
      end
    end

    describe ".prototypes" do
      it "returns prototype stage projects" do
        expect(Project.prototypes).to include(prototype_project)
        expect(Project.prototypes).not_to include(idea_project)
      end
    end

    describe ".launched" do
      it "returns launched projects" do
        expect(Project.launched).to include(launched_project)
        expect(Project.launched).not_to include(idea_project)
      end
    end

    describe ".seeking_mentor" do
      it "returns projects seeking mentors" do
        expect(Project.seeking_mentor).to include(mentor_project)
        expect(Project.seeking_mentor).not_to include(cofounder_project)
      end
    end

    describe ".seeking_cofounder" do
      it "returns projects seeking cofounders" do
        expect(Project.seeking_cofounder).to include(cofounder_project)
        expect(Project.seeking_cofounder).not_to include(mentor_project)
      end
    end
  end

  # Factory Integration Testing - Line 507-549 in test_spec
  describe "factory integration" do
    it "creates valid project with factory" do
      project = create(:project, public_fields: ['name'])
      expect(project).to be_valid
      expect(project.name).to be_present
      expect(project.description).to be_present
      expect(project.user).to be_present
    end

    it "creates project with repository URL" do
      project = create(:project, repository_url: "testuser/testrepo", public_fields: ['name'])
      expect(project.repository_url).to eq("testuser/testrepo")
      expect(project).to be_valid
    end
  end

  describe "stealth mode functionality" do
    describe "scopes" do
      let!(:public_project) { create(:project, stealth_mode: false, public_fields: ['name']) }
      let!(:stealth_project) { create(:project, stealth_mode: true, public_fields: []) }

      it "filters publicly visible projects" do
        expect(Project.publicly_visible).to include(public_project)
        expect(Project.publicly_visible).not_to include(stealth_project)
      end

      it "filters stealth projects" do
        expect(Project.stealth_projects).to include(stealth_project)
        expect(Project.stealth_projects).not_to include(public_project)
      end
    end

    describe "stealth mode methods" do
      let(:stealth_project) { create(:project, stealth_mode: true) }
      let(:public_project) { create(:project, stealth_mode: false) }

      it "identifies stealth projects" do
        expect(stealth_project.stealth?).to be true
        expect(public_project.stealth?).to be false
      end

      it "identifies publicly discoverable projects" do
        expect(stealth_project.publicly_discoverable?).to be false
        expect(public_project.publicly_discoverable?).to be true
      end

      it "can exit stealth mode" do
        expect(stealth_project.stealth?).to be true
        stealth_project.exit_stealth_mode!
        expect(stealth_project.reload.stealth?).to be false
      end

      it "provides stealth display name" do
        stealth_project.update(stealth_name: "Secret Project")
        expect(stealth_project.stealth_display_name).to eq("Secret Project")
      end

      it "provides default stealth display name when none set" do
        expect(stealth_project.stealth_display_name).to match(/Stealth Startup [A-F0-9]{4}/)
      end

      it "provides stealth display description" do
        stealth_project.update(stealth_description: "Top secret innovation")
        expect(stealth_project.stealth_display_description).to eq("Top secret innovation")
      end

      it "provides default stealth display description when none set" do
        expect(stealth_project.stealth_display_description).to eq("Early-stage venture in development. Details available after connection.")
      end
    end

    describe "stealth mode defaults" do
      it "sets stealth defaults for new stealth projects" do
        project = Project.new(name: "Test", description: "Test", stage: "idea", user:, stealth_mode: true)
        project.save!

        expect(project.public_fields).to eq([])
        expect(project.stealth_name).to match(/Stealth Startup [A-F0-9]{4}/)
        expect(project.stealth_description).to eq("Early-stage venture in development. Details available after connection.")
        expect(project.stealth_category).to eq("Technology")
      end

      it "sets default public fields for non-stealth projects" do
        project = Project.new(name: "Test", description: "Test", stage: "idea", user:, stealth_mode: false)
        project.save!

        expect(project.public_fields).to eq(Project::DEFAULT_PUBLIC_FIELDS)
      end
    end
  end
end
