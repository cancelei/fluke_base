require 'rails_helper'

# Milestone Model Testing - Following patterns from technical_spec/test_spec/ruby_testing/README.md:42-349
# Reference: Comprehensive Model Testing section for association, validation, and business logic patterns

RSpec.describe Milestone, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }
  let(:milestone) { create(:milestone, project:) }

  # Association Testing - Line 49-58 in test_spec
  describe "associations" do
    it { should belong_to(:project) }
    it { should have_many(:time_logs).dependent(:destroy) }
    it { should have_many(:milestone_enhancements).dependent(:destroy) }
  end

  # Validation Testing with Context - Line 60-102 in test_spec
  describe "validations" do
    subject { create(:milestone) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:due_date) }
  end

  # Business Logic Testing - Line 129-148 in test_spec
  describe "instance methods" do
    describe "#completed?" do
      it "returns true when status is completed" do
        milestone = build(:milestone, status: "completed")
        expect(milestone.completed?).to be true
      end

      it "returns false when status is not completed" do
        milestone = build(:milestone, status: "in_progress")
        expect(milestone.completed?).to be false
      end
    end

    describe "#completed?" do
      it "returns true when status is completed" do
        milestone.status = "completed"
        expect(milestone.completed?).to be true
      end

      it "returns false when status is not completed" do
        milestone.status = "pending"
        expect(milestone.completed?).to be false
      end
    end

    describe "#can_be_enhanced?" do
      it "returns true when description is present" do
        milestone.description = "Some description"
        expect(milestone.can_be_enhanced?).to be true
      end

      it "returns false when description is blank" do
        milestone.description = ""
        expect(milestone.can_be_enhanced?).to be false
      end
    end
  end

  describe "actual_status and time-log aware states" do
    let(:owner) { user }
    let(:milestone_for_status) { create(:milestone, project:, status: Milestone::PENDING) }

    it "returns completed when explicitly completed" do
      ms = create(:milestone, project:, status: Milestone::COMPLETED)
      expect(ms.actual_status).to eq(Milestone::COMPLETED)
    end

    it "respects explicit in_progress without time logs" do
      ms = create(:milestone, project:, status: Milestone::IN_PROGRESS)
      expect(ms.actual_status).to eq(Milestone::IN_PROGRESS)
    end

    it "returns pending when no logs and status pending" do
      expect(milestone_for_status.actual_status).to eq(Milestone::PENDING)
    end

    it "becomes in_progress when owner logs time" do
      tl = create(:time_log, project:, milestone: milestone_for_status, user: owner, hours_spent: 1.5, status: "completed")
      expect(milestone_for_status.reload.actual_status).to eq(Milestone::IN_PROGRESS)
    end

    it "remains pending when only unauthorized user logs time" do
      outsider = create(:user)
      create(:time_log, project:, milestone: milestone_for_status, user: outsider, hours_spent: 1.0, status: "completed")
      # No agreements yet, outsider is not authorized
      expect(milestone_for_status.reload.actual_status).to eq(Milestone::PENDING)
    end

    it "becomes in_progress when active agreement participant logs time" do
      mentor = create(:user)
      # Create accepted agreement so mentor is an authorized participant
      create(:agreement, :with_participants, :mentorship, project:, initiator: owner, other_party: mentor, status: Agreement::ACCEPTED)
      create(:time_log, project:, milestone: milestone_for_status, user: mentor, hours_spent: 2.0, status: "completed")
      expect(milestone_for_status.reload.actual_status).to eq(Milestone::IN_PROGRESS)
    end
  end

  describe "helper predicates" do
    it "in_progress? reflects actual_status" do
      ms = create(:milestone, project:, status: Milestone::IN_PROGRESS)
      expect(ms.in_progress?).to be true
      ms.update!(status: Milestone::PENDING)
      expect(ms.in_progress?).to be false
    end

    it "not_started? and pending? are true when actual_status is pending" do
      ms = create(:milestone, project:, status: Milestone::PENDING)
      expect(ms.not_started?).to be true
      expect(ms.pending?).to be true
    end
  end

  describe "scopes with due dates" do
    it "upcoming returns milestones with future due dates ordered asc" do
      past  = create(:milestone, project:, due_date: Date.today - 1, status: Milestone::PENDING)
      soon  = create(:milestone, project:, due_date: Date.today + 1, status: Milestone::PENDING)
      later = create(:milestone, project:, due_date: Date.today + 7, status: Milestone::PENDING)

      list = Milestone.upcoming.to_a
      expect(list).to include(soon, later)
      expect(list).not_to include(past)
      expect(list.map(&:due_date)).to eq(list.map(&:due_date).sort)
    end
  end

  # Scope Testing - Line 104-126 in test_spec
  describe "scopes" do
    let!(:pending_milestone) { create(:milestone, status: "pending") }
    let!(:completed_milestone) { create(:milestone, status: "completed") }
    let!(:in_progress_milestone) { create(:milestone, status: "in_progress") }

    describe ".pending" do
      it "returns pending milestones" do
        expect(Milestone.pending).to include(pending_milestone)
        expect(Milestone.pending).not_to include(completed_milestone)
      end
    end

    describe ".completed" do
      it "returns completed milestones" do
        expect(Milestone.completed).to include(completed_milestone)
        expect(Milestone.completed).not_to include(pending_milestone)
      end
    end

    describe ".in_progress" do
      it "returns in progress milestones" do
        expect(Milestone.in_progress).to include(in_progress_milestone)
        expect(Milestone.in_progress).not_to include(completed_milestone)
      end
    end
  end

  # Factory Integration Testing - Line 507-549 in test_spec
  describe "factory integration" do
    it "creates valid milestone with factory" do
      milestone = create(:milestone)
      expect(milestone).to be_valid
      expect(milestone.title).to be_present
      expect(milestone.project).to be_present
    end
  end
end
