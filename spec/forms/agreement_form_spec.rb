require 'rails_helper'

RSpec.describe AgreementForm, type: :model do
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }
  let(:project) { create(:project, user: alice) }
  let(:milestone1) { create(:milestone, project: project) }
  let(:milestone2) { create(:milestone, project: project) }

  let(:valid_attributes) do
    {
      project_id: project.id,
      initiator_user_id: alice.id,
      other_party_user_id: bob.id,
      agreement_type: Agreement::MENTORSHIP,
      payment_type: Agreement::HOURLY,
      start_date: 1.week.from_now.to_date,
      end_date: 4.weeks.from_now.to_date,
      tasks: "Help with project development",
      weekly_hours: 10,
      hourly_rate: 75.0,
      milestone_ids: "#{milestone1.id},#{milestone2.id}"
    }
  end

  describe "validations" do
    subject {
      # Ensure milestones exist before creating form
      milestone1
      milestone2
      AgreementForm.new(valid_attributes)
    }

    it { should validate_presence_of(:project_id) }
    it { should validate_presence_of(:initiator_user_id) }
    it { should validate_presence_of(:other_party_user_id) }
    it { should validate_presence_of(:agreement_type) }
    it { should validate_presence_of(:payment_type) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:tasks) }
    it { should validate_presence_of(:weekly_hours) }

    it { should validate_numericality_of(:weekly_hours).is_greater_than(0).is_less_than_or_equal_to(40) }

    context "when payment type is hourly" do
      subject { AgreementForm.new(valid_attributes.merge(payment_type: Agreement::HOURLY)) }
      it { should validate_presence_of(:hourly_rate) }
      it { should validate_numericality_of(:hourly_rate).is_greater_than_or_equal_to(0) }
    end

    context "when payment type is equity" do
      subject { AgreementForm.new(valid_attributes.merge(payment_type: Agreement::EQUITY, equity_percentage: 15.0)) }
      it { should validate_presence_of(:equity_percentage) }
      it { should validate_numericality_of(:equity_percentage).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
    end

    context "when payment type is hybrid" do
      subject { AgreementForm.new(valid_attributes.merge(payment_type: Agreement::HYBRID, equity_percentage: 10.0)) }
      it { should validate_presence_of(:hourly_rate) }
      it { should validate_presence_of(:equity_percentage) }
    end

    context "when agreement type is mentorship" do
      subject { AgreementForm.new(valid_attributes.merge(agreement_type: Agreement::MENTORSHIP)) }
      it { should validate_presence_of(:milestone_ids) }
    end

    describe "end_date_after_start_date" do
      it "is valid when end date is after start date" do
        # Ensure milestones exist and are persisted before creating form
        m1 = milestone1
        m2 = milestone2
        # Force persistence
        m1.save!
        m2.save!

        # Create attributes with actual milestone IDs
        attributes = valid_attributes.merge(milestone_ids: "#{m1.id},#{m2.id}")
        form = AgreementForm.new(attributes)
        expect(form).to be_valid
      end

      it "is invalid when end date is before start date" do
        # Ensure milestones exist before creating form
        milestone1
        milestone2
        form = AgreementForm.new(valid_attributes.merge(
          start_date: 4.weeks.from_now.to_date,
          end_date: 1.week.from_now.to_date
        ))
        expect(form).not_to be_valid
        expect(form.errors[:end_date]).to include("must be after the start date")
      end
    end

    describe "different_parties" do
      it "is invalid when initiator and other party are the same" do
        form = AgreementForm.new(valid_attributes.merge(other_party_user_id: alice.id))
        expect(form).not_to be_valid
        expect(form.errors[:base]).to include("Initiator and other party cannot be the same person")
      end
    end

    describe "no_duplicate_agreement" do
      it "prevents duplicate agreements" do
        create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob)

        form = AgreementForm.new(valid_attributes)
        expect(form).not_to be_valid
        expect(form.errors[:base]).to include("An agreement already exists between these parties for this project")
      end

      it "allows counter offers" do
        original = create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob)

        form = AgreementForm.new(valid_attributes.merge(counter_agreement_id: original.id))
        expect(form).to be_valid
      end
    end
  end

  describe "milestone handling" do
    describe "#milestone_ids_array" do
      it "parses comma-separated string" do
        form = AgreementForm.new(milestone_ids: "#{milestone1.id},#{milestone2.id}")
        expect(form.milestone_ids_array).to contain_exactly(milestone1.id, milestone2.id)
      end

      it "handles array input" do
        form = AgreementForm.new(milestone_ids: [ milestone1.id, milestone2.id ])
        expect(form.milestone_ids_array).to contain_exactly(milestone1.id, milestone2.id)
      end

      it "handles JSON string" do
        json_string = [ milestone1.id, milestone2.id ].to_json
        form = AgreementForm.new(milestone_ids: json_string)
        expect(form.milestone_ids_array).to contain_exactly(milestone1.id, milestone2.id)
      end

      it "handles empty values" do
        form = AgreementForm.new(milestone_ids: "")
        expect(form.milestone_ids_array).to eq([])

        form = AgreementForm.new(milestone_ids: nil)
        expect(form.milestone_ids_array).to eq([])
      end

      it "filters out zero values" do
        form = AgreementForm.new(milestone_ids: "#{milestone1.id},0,#{milestone2.id}")
        expect(form.milestone_ids_array).to contain_exactly(milestone1.id, milestone2.id)
      end
    end

    describe "#selected_milestones" do
      it "returns selected milestone objects" do
        form = AgreementForm.new(valid_attributes)
        selected = form.selected_milestones
        expect(selected).to contain_exactly(milestone1, milestone2)
      end

      it "returns empty array when no project" do
        form = AgreementForm.new(project_id: nil, milestone_ids: "#{milestone1.id}")
        expect(form.selected_milestones).to eq([])
      end
    end
  end

  describe "associated objects" do
    let(:form) { AgreementForm.new(valid_attributes) }

    it "loads project" do
      expect(form.project).to eq(project)
    end

    it "loads initiator" do
      expect(form.initiator).to eq(alice)
    end

    it "loads other party" do
      expect(form.other_party).to eq(bob)
    end

    context "with counter offer" do
      let(:original_agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: bob, other_party: alice) }
      let(:counter_form) { AgreementForm.new(valid_attributes.merge(counter_agreement_id: original_agreement.id)) }

      it "loads counter agreement" do
        expect(counter_form.counter_to).to eq(original_agreement)
      end

      it "identifies as counter offer" do
        expect(counter_form.is_counter_offer?).to be true
        expect(form.is_counter_offer?).to be false
      end
    end
  end

  describe "agreement type determination" do
    it "determines mentorship for agreements with weekly hours" do
      form = AgreementForm.new(weekly_hours: 10, agreement_type: nil)
      expect(form.send(:determine_agreement_type)).to eq(Agreement::MENTORSHIP)
    end

    it "determines co-founder for agreements without weekly hours" do
      form = AgreementForm.new(weekly_hours: nil, agreement_type: nil)
      expect(form.send(:determine_agreement_type)).to eq(Agreement::CO_FOUNDER)
    end
  end

  describe "user role determination" do
    let(:form) { AgreementForm.new(valid_attributes) }

    it "assigns entrepreneur role to project owner" do
      role = form.send(:determine_user_role, alice.id)
      expect(role).to eq("entrepreneur")
    end

    it "assigns mentor role for mentorship agreements" do
      role = form.send(:determine_user_role, bob.id)
      expect(role).to eq("mentor")
    end

    it "assigns co_founder role for co-founder agreements" do
      co_founder_form = AgreementForm.new(valid_attributes.merge(agreement_type: Agreement::CO_FOUNDER))
      role = co_founder_form.send(:determine_user_role, bob.id)
      expect(role).to eq("co_founder")
    end

    it "assigns collaborator role as default" do
      other_form = AgreementForm.new(valid_attributes.merge(agreement_type: "Unknown"))
      role = other_form.send(:determine_user_role, bob.id)
      expect(role).to eq("collaborator")
    end
  end

  describe "save and create" do
    it "creates agreement with participants" do
      form = AgreementForm.new(valid_attributes)

      expect {
        expect(form.save).to be true
      }.to change(Agreement, :count).by(1)
        .and change(AgreementParticipant, :count).by(2)

      agreement = form.agreement
      expect(agreement.project).to eq(project)
      expect(agreement.initiator).to eq(alice)
      expect(agreement.other_party).to eq(bob)
      expect(agreement.milestone_ids).to contain_exactly(milestone1.id, milestone2.id)

      # Check participants
      initiator_participant = agreement.agreement_participants.find_by(is_initiator: true)
      expect(initiator_participant.user).to eq(alice)
      expect(initiator_participant.user_role).to eq("entrepreneur")

      other_participant = agreement.agreement_participants.find_by(is_initiator: false)
      expect(other_participant.user).to eq(bob)
      expect(other_participant.user_role).to eq("mentor")
      expect(other_participant.accept_or_counter_turn_id).to eq(bob.id)
    end

    it "handles save errors gracefully" do
      form = AgreementForm.new(valid_attributes.merge(weekly_hours: nil))

      expect(form.save).to be false
      expect(form.errors[:weekly_hours]).to include("can't be blank")
    end
  end

  describe "counter offer creation" do
    let(:original_agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: bob, other_party: alice) }

    it "creates counter offer and updates original agreement" do
      form = AgreementForm.new(valid_attributes.merge(
        counter_agreement_id: original_agreement.id,
        hourly_rate: 85.0
      ))

      expect(form.save).to be true

      counter_agreement = form.agreement
      original_agreement.reload

      expect(original_agreement.status).to eq(Agreement::COUNTERED)
      expect(counter_agreement.counter_to).to eq(original_agreement)
      expect(counter_agreement.hourly_rate).to eq(85.0)
    end
  end

  describe "update functionality" do
    let(:existing_agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

    it "updates existing agreement" do
      form = AgreementForm.new(valid_attributes.merge(
        tasks: "Updated tasks",
        weekly_hours: 15
      ))

      result = form.update_agreement(existing_agreement)
      existing_agreement.reload

      expect(result).to be_truthy
      expect(existing_agreement.tasks).to eq("Updated tasks")
      expect(existing_agreement.weekly_hours).to eq(15)
    end

    it "recreates participants on update" do
      original_participant_ids = existing_agreement.agreement_participants.pluck(:id)

      form = AgreementForm.new(valid_attributes.merge(tasks: "Updated tasks"))
      form.update_agreement(existing_agreement)

      new_participant_ids = existing_agreement.reload.agreement_participants.pluck(:id)
      expect(new_participant_ids).not_to match_array(original_participant_ids)
      expect(new_participant_ids.count).to eq(2)
    end
  end

  describe "validation edge cases" do
    it "validates payment terms for different payment types" do
      # Test hourly payment without rate
      form = AgreementForm.new(valid_attributes.merge(
        payment_type: Agreement::HOURLY,
        hourly_rate: nil
      ))
      expect(form).not_to be_valid
      expect(form.errors[:hourly_rate]).to include("must be present for hourly payment")

      # Test equity payment without percentage
      form = AgreementForm.new(valid_attributes.merge(
        payment_type: Agreement::EQUITY,
        equity_percentage: nil,
        hourly_rate: nil
      ))
      expect(form).not_to be_valid
      expect(form.errors[:equity_percentage]).to include("must be present for equity payment")

      # Test hybrid payment missing both
      form = AgreementForm.new(valid_attributes.merge(
        payment_type: Agreement::HYBRID,
        hourly_rate: nil,
        equity_percentage: nil
      ))
      expect(form).not_to be_valid
      expect(form.errors[:hourly_rate]).to include("must be present for hybrid payment")
      expect(form.errors[:equity_percentage]).to include("must be present for hybrid payment")
    end
  end
end
