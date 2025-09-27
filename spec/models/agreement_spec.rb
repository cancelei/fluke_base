require 'rails_helper'

RSpec.describe Agreement, type: :model do
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }
  let(:project) { create(:project, user: alice) }
  let(:milestone1) { create(:milestone, project: project) }
  let(:milestone2) { create(:milestone, project: project) }

  describe "associations" do
    it { should belong_to(:project) }
    it { should have_many(:agreement_participants).dependent(:destroy) }
    it { should have_many(:users).through(:agreement_participants) }
    it { should have_many(:meetings).dependent(:destroy) }
    it { should have_many(:github_logs).dependent(:destroy) }
  end

  describe "validations" do
    subject { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

    it { should validate_presence_of(:project_id) }
    # Note: status and agreement_type are auto-set by before_validation callbacks
    # So we test the inclusion validations instead of presence
    it { should validate_presence_of(:payment_type) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:tasks) }
    # weekly_hours presence is only required for mentorship agreements

    it { should validate_inclusion_of(:status).in_array([
      Agreement::PENDING, Agreement::ACCEPTED, Agreement::REJECTED,
      Agreement::COMPLETED, Agreement::CANCELLED, Agreement::COUNTERED
    ]) }

    it "validates agreement type inclusion" do
      agreement = build(:agreement, :co_founder, project: project)
      # Set an invalid type and skip callbacks to test validation
      agreement.agreement_type = "Invalid"
      agreement.valid?
      expect(agreement.errors[:agreement_type]).to include("is not included in the list")
    end

    it { should validate_inclusion_of(:payment_type).in_array([
      Agreement::HOURLY, Agreement::EQUITY, Agreement::HYBRID
    ]) }

    context "when payment type is hourly" do
      subject { build(:agreement, payment_type: Agreement::HOURLY) }
      it { should validate_presence_of(:hourly_rate) }
      it { should validate_numericality_of(:hourly_rate).is_greater_than_or_equal_to(0) }
    end

    context "when payment type is equity" do
      subject { build(:agreement, payment_type: Agreement::EQUITY) }
      it { should validate_presence_of(:equity_percentage) }
      it { should validate_numericality_of(:equity_percentage).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
    end

    context "when agreement type is mentorship" do
      subject { build(:agreement, :mentorship, project: project) }
      it { should validate_presence_of(:milestone_ids) }
      it { should validate_presence_of(:weekly_hours) }
      it { should validate_numericality_of(:weekly_hours).is_greater_than(0).is_less_than_or_equal_to(40) }
    end

    describe "end_date_after_start_date" do
      it "is valid when end date is after start date" do
        agreement = build(:agreement, :co_founder,
          project: project,
          start_date: 1.week.from_now,
          end_date: 2.weeks.from_now
        )
        expect(agreement).to be_valid
      end

      it "is invalid when end date is before start date" do
        agreement = build(:agreement, :co_founder,
          project: project,
          start_date: 2.weeks.from_now,
          end_date: 1.week.from_now
        )
        expect(agreement).not_to be_valid
        expect(agreement.errors[:end_date]).to include("must be after the start date")
      end
    end
  end

  describe "scopes" do
    let!(:mentorship) { create(:agreement, :mentorship) }
    let!(:co_founder) { create(:agreement, :co_founder) }
    let!(:pending_agreement) { create(:agreement, :co_founder, status: Agreement::PENDING) }
    let!(:accepted_agreement) { create(:agreement, :co_founder, :accepted) }

    it "filters by agreement type" do
      expect(Agreement.mentorships).to include(mentorship)
      expect(Agreement.mentorships).not_to include(co_founder)
      expect(Agreement.co_founding).to include(co_founder)
      expect(Agreement.co_founding).not_to include(mentorship)
    end

    it "filters by status" do
      expect(Agreement.pending).to include(pending_agreement)
      expect(Agreement.pending).not_to include(accepted_agreement)
      expect(Agreement.active).to include(accepted_agreement)
      expect(Agreement.active).not_to include(pending_agreement)
    end

    it "orders by creation date" do
      older = create(:agreement, created_at: 2.days.ago)
      newer = create(:agreement, created_at: 1.day.ago)

      # Verify relative ordering without destructive global cleanup
      ids = Agreement.recent_first.pluck(:id)
      expect(ids.index(newer.id)).to be < ids.index(older.id)
    end
  end

  describe "status methods" do
    let(:agreement) { create(:agreement, :co_founder) }

    it "recognizes pending status" do
      agreement.update!(status: Agreement::PENDING)
      expect(agreement).to be_pending
      expect(agreement).not_to be_active
      expect(agreement).not_to be_completed
    end

    it "recognizes accepted status" do
      agreement.update!(status: Agreement::ACCEPTED)
      expect(agreement).to be_active
      expect(agreement).not_to be_pending
      expect(agreement).not_to be_completed
    end

    it "recognizes completed status" do
      agreement.update!(status: Agreement::COMPLETED)
      expect(agreement).to be_completed
      expect(agreement).not_to be_pending
      expect(agreement).not_to be_active
    end
  end

  describe "participant methods" do
    let(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

    it "identifies the initiator" do
      expect(agreement.initiator).to eq(alice)
      expect(agreement.initiator_id).to eq(alice.id)
    end

    it "identifies the other party" do
      expect(agreement.other_party).to eq(bob)
      expect(agreement.other_party_id).to eq(bob.id)
    end

    it "provides all participants" do
      participants = agreement.participants
      expect(participants.count).to eq(2)
      expect(participants.map(&:user)).to contain_exactly(alice, bob)
    end

    it "finds participant for specific user" do
      alice_participant = agreement.participant_for_user(alice)
      expect(alice_participant.user).to eq(alice)
      expect(alice_participant).to be_initiator
    end
  end

  describe "turn-based system" do
    let(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

    it "determines whose turn it is" do
      # By default, it should be the other party's turn (bob)
      expect(agreement.whose_turn?).to eq(bob)
    end

    it "can pass turn to other party" do
      agreement.pass_turn_to_other_party(alice)
      expect(agreement.whose_turn?).to eq(bob)

      agreement.pass_turn_to_other_party(bob)
      expect(agreement.whose_turn?).to eq(alice)
    end

    it "checks if user can accept or counter" do
      expect(agreement.user_can_accept_or_counter?(bob)).to be true
      expect(agreement.user_can_accept_or_counter?(alice)).to be false
    end
  end

  describe "milestone handling" do
    let(:agreement) { create(:agreement, :mentorship, project: project, milestone_ids: [ milestone1.id, milestone2.id ]) }

    it "handles milestone IDs as array" do
      expect(agreement.milestone_ids).to contain_exactly(milestone1.id, milestone2.id)
    end

    it "finds selected milestones" do
      selected = agreement.selected_milestones
      expect(selected).to contain_exactly(milestone1, milestone2)
    end

    it "handles empty milestone IDs" do
      agreement.milestone_ids = []
      expect(agreement.milestone_ids).to eq([])
      expect(agreement.selected_milestones).to be_empty
    end
  end

  describe "counter offer system" do
    let(:original_agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }
    let(:counter_agreement) do
      create(:agreement, :with_participants, :mentorship, project: project, initiator: bob, other_party: alice).tap do |agreement|
        agreement.agreement_participants.update_all(counter_agreement_id: original_agreement.id)
      end
    end

    it "identifies counter offers" do
      expect(counter_agreement.is_counter_offer?).to be true
      expect(original_agreement.is_counter_offer?).to be false
    end

    it "links to original agreement" do
      expect(counter_agreement.counter_to).to eq(original_agreement)
      expect(counter_agreement.counter_to_id).to eq(original_agreement.id)
    end

    it "finds counter offers made to original" do
      counter_agreement # Create the counter offer
      expect(original_agreement.counter_offers).to include(counter_agreement)
      expect(original_agreement.has_counter_offers?).to be true
    end

    it "finds most recent counter offer" do
      first_counter = counter_agreement
      second_counter = create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob).tap do |agreement|
        agreement.agreement_participants.update_all(counter_agreement_id: original_agreement.id)
        agreement.update!(created_at: 1.day.from_now)
      end

      expect(original_agreement.most_recent_counter_offer).to eq(second_counter)
      expect(original_agreement.latest_counter_offer).to eq(second_counter)
    end
  end

  describe "status transitions" do
    let(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

    describe "#accept!" do
      it "transitions from pending to accepted" do
        expect(agreement.status).to eq(Agreement::PENDING)
        result = agreement.accept!
        expect(result).to be_truthy
        expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
      end

      it "fails when not pending" do
        agreement.update!(status: Agreement::ACCEPTED)
        result = agreement.accept!
        expect(result).to be_falsey
      end
    end

    describe "#reject!" do
      it "transitions from pending to rejected" do
        result = agreement.reject!
        expect(result).to be_truthy
        expect(agreement.reload.status).to eq(Agreement::REJECTED)
      end
    end

    describe "#complete!" do
      it "transitions from accepted to completed" do
        agreement.update!(status: Agreement::ACCEPTED)
        result = agreement.complete!
        expect(result).to be_truthy
        expect(agreement.reload.status).to eq(Agreement::COMPLETED)
      end

      it "fails when not accepted" do
        expect(agreement.status).to eq(Agreement::PENDING)
        result = agreement.complete!
        expect(result).to be_falsey
        expect(agreement.reload.status).to eq(Agreement::PENDING)
      end
    end

    describe "#cancel!" do
      it "transitions from pending to cancelled" do
        result = agreement.cancel!
        expect(result).to be_truthy
        expect(agreement.reload.status).to eq(Agreement::CANCELLED)
      end
    end
  end

  describe "access control" do
    let(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }
    let(:charlie) { create(:user) }

    it "allows participants to view full project details" do
      expect(agreement.can_view_full_project_details?(alice)).to be true
      expect(agreement.can_view_full_project_details?(bob)).to be true
      expect(agreement.can_view_full_project_details?(charlie)).to be false
    end
  end

  describe "calculations" do
    let(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob, weekly_hours: 10, hourly_rate: 50.0) }

    it "calculates duration in weeks" do
      agreement.update!(start_date: Date.current, end_date: 4.weeks.from_now.to_date)
      expect(agreement.duration_in_weeks).to eq(4)
    end

    it "calculates total cost for hourly agreements" do
      agreement.update!(
        start_date: Date.current,
        end_date: 4.weeks.from_now.to_date,
        weekly_hours: 10,
        hourly_rate: 50.0
      )
      expected_cost = 4 * 10 * 50.0  # 4 weeks * 10 hours * $50
      expect(agreement.calculate_total_cost).to eq(expected_cost)
    end
  end

  describe "callbacks and initialization" do
    it "sets default status to pending when blank" do
      agreement = Agreement.new
      agreement.valid? # Trigger callbacks
      expect(agreement.status).to eq(Agreement::PENDING)
    end

    it "determines agreement type based on weekly hours" do
      agreement = Agreement.new(weekly_hours: 10)
      agreement.valid? # Trigger callbacks
      expect(agreement.agreement_type).to eq(Agreement::MENTORSHIP)

      agreement = Agreement.new(weekly_hours: nil)
      agreement.valid? # Trigger callbacks
      expect(agreement.agreement_type).to eq(Agreement::CO_FOUNDER)
    end

    it "does not override existing status and agreement_type" do
      agreement = Agreement.new(status: Agreement::ACCEPTED, agreement_type: Agreement::CO_FOUNDER)
      agreement.valid? # Trigger callbacks
      expect(agreement.status).to eq(Agreement::ACCEPTED)
      expect(agreement.agreement_type).to eq(Agreement::CO_FOUNDER)
    end
  end

  describe "payment boundaries and date edges" do
    it "allows same-day start and end dates" do
      project = create(:project)
      agreement = build(:agreement, :co_founder, project: project, start_date: Date.today, end_date: Date.today)
      expect(agreement).to be_valid
    end

    context "hourly payments" do
      it "requires hourly_rate and accepts 0+" do
        project = create(:project)
        a = build(:agreement, :mentorship, project: project, payment_type: Agreement::HOURLY, hourly_rate: nil)
        expect(a).not_to be_valid
        a.hourly_rate = 0
        expect(a).to be_valid
        a.hourly_rate = -1
        expect(a).not_to be_valid
      end
    end

    context "equity payments" do
      it "requires equity_percentage and enforces 0..100" do
        project = create(:project)
        a = build(:agreement, :co_founder, project: project, payment_type: Agreement::EQUITY, equity_percentage: nil)
        expect(a).not_to be_valid
        a.equity_percentage = 0
        expect(a).to be_valid
        a.equity_percentage = 100
        expect(a).to be_valid
        a.equity_percentage = 101
        expect(a).not_to be_valid
      end
    end

    context "hybrid payments" do
      it "require both hourly_rate and equity_percentage" do
        project = create(:project)
        a = build(:agreement, :mentorship, project: project, payment_type: Agreement::HYBRID, hourly_rate: nil, equity_percentage: 10)
        expect(a).not_to be_valid
        a.hourly_rate = 30
        a.equity_percentage = nil
        expect(a).not_to be_valid
        a.equity_percentage = 5
        expect(a).to be_valid
      end
    end

    context "mentorship requirements" do
      it "requires weekly_hours and milestone_ids" do
        project = create(:project)
        a = build(:agreement, :mentorship, project: project)
        # Remove milestone_ids to test presence
        a.milestone_ids = []
        expect(a).not_to be_valid
        a.milestone_ids = [ create(:milestone, project: project).id ]
        a.weekly_hours = nil
        expect(a).not_to be_valid
        a.weekly_hours = 5
        expect(a).to be_valid
      end
    end
  end
end
