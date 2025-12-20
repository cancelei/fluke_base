require 'rails_helper'

RSpec.describe AgreementParticipant, type: :model do
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }
  let(:project) { create(:project, user: alice) }
  let(:agreement) { create(:agreement, project:) }
  let(:agreement_with_participants) { create(:agreement, :with_participants, project:, initiator: alice, other_party: bob) }

  describe "associations" do
    it { should belong_to(:agreement) }
    it { should belong_to(:user) }
    it { should belong_to(:project) }
    it { should belong_to(:counter_agreement).class_name("Agreement").optional }
    it { should belong_to(:accept_or_counter_turn).class_name("User").optional }
  end

  describe "validations" do
    subject { create(:agreement_participant, agreement:, user: alice, project:) }

    it { should validate_presence_of(:agreement_id) }
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:project_id) }
    it { should validate_presence_of(:user_role) }
    it { should allow_value(true).for(:is_initiator) }
    it { should allow_value(false).for(:is_initiator) }
    it { should_not allow_value(nil).for(:is_initiator) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:agreement_id) }
  end

  describe "scopes" do
    let!(:initiator_participant) { agreement_with_participants.agreement_participants.find_by(is_initiator: true) }
    let!(:other_participant) { agreement_with_participants.agreement_participants.find_by(is_initiator: false) }

    it "filters initiators" do
      expect(AgreementParticipant.initiators).to include(initiator_participant)
      expect(AgreementParticipant.initiators).not_to include(other_participant)
    end

    it "filters non-initiators" do
      expect(AgreementParticipant.non_initiators).to include(other_participant)
      expect(AgreementParticipant.non_initiators).not_to include(initiator_participant)
    end

    it "filters by user" do
      alice_participants = AgreementParticipant.for_user(alice)
      expect(alice_participants).to include(initiator_participant)
      expect(alice_participants).not_to include(other_participant)
    end

    it "filters by agreement" do
      agreement_participants = AgreementParticipant.for_agreement(agreement_with_participants)
      expect(agreement_participants).to include(initiator_participant, other_participant)
    end
  end

  describe "class methods" do
    let!(:initiator_participant) { agreement_with_participants.agreement_participants.find_by(is_initiator: true) }
    let!(:other_participant) { agreement_with_participants.agreement_participants.find_by(is_initiator: false) }

    describe ".find_initiator" do
      it "finds the initiator participant" do
        found = AgreementParticipant.find_initiator(agreement_with_participants)
        expect(found).to eq(initiator_participant)
        expect(found.user).to eq(alice)
      end
    end

    describe ".find_other_party" do
      it "finds the other party participant for alice" do
        found = AgreementParticipant.find_other_party(agreement_with_participants, alice)
        expect(found).to eq(other_participant)
        expect(found.user).to eq(bob)
      end

      it "finds the other party participant for bob" do
        found = AgreementParticipant.find_other_party(agreement_with_participants, bob)
        expect(found).to eq(initiator_participant)
        expect(found.user).to eq(alice)
      end
    end

    describe ".find_participants" do
      it "finds all participants for an agreement" do
        found = AgreementParticipant.find_participants(agreement_with_participants)
        expect(found.count).to eq(2)
        expect(found).to include(initiator_participant, other_participant)
      end
    end
  end

  describe "instance methods" do
    let(:initiator_participant) { agreement_with_participants.agreement_participants.find_by(is_initiator: true) }
    let(:other_participant) { agreement_with_participants.agreement_participants.find_by(is_initiator: false) }

    describe "#initiator?" do
      it "correctly identifies initiator" do
        expect(initiator_participant).to be_initiator
        expect(other_participant).not_to be_initiator
      end
    end

    describe "#other_participants" do
      it "finds other participants in the same agreement" do
        others = initiator_participant.other_participants
        expect(others).to include(other_participant)
        expect(others).not_to include(initiator_participant)
      end
    end

    describe "turn-based system" do
      describe "#is_turn_to_act?" do
        it "correctly identifies when it's participant's turn" do
          # By default, other party (bob) has the turn
          expect(other_participant.is_turn_to_act?).to be true
          expect(initiator_participant.is_turn_to_act?).to be false
        end
      end

      describe "#can_accept_or_counter?" do
        it "allows action when it's participant's turn and agreement is pending" do
          expect(other_participant.can_accept_or_counter?).to be true
          expect(initiator_participant.can_accept_or_counter?).to be false
        end

        it "prevents action when agreement is not pending" do
          agreement_with_participants.update!(status: Agreement::ACCEPTED)
          expect(other_participant.can_accept_or_counter?).to be false
        end
      end

      describe "#can_make_counter_offer?" do
        it "allows counter offers when it's participant's turn and agreement is pending" do
          expect(other_participant.can_make_counter_offer?).to be true
          expect(initiator_participant.can_make_counter_offer?).to be false
        end
      end

      describe "#can_accept_agreement?" do
        it "allows acceptance when it's participant's turn and agreement is pending" do
          expect(other_participant.can_accept_agreement?).to be true
          expect(initiator_participant.can_accept_agreement?).to be false
        end
      end

      describe "#can_reject_agreement?" do
        it "allows rejection when it's participant's turn and agreement is pending" do
          expect(other_participant.can_reject_agreement?).to be true
          expect(initiator_participant.can_reject_agreement?).to be false
        end
      end

      describe "#pass_turn_to" do
        it "passes the turn to specified user" do
          charlie = create(:user)
          other_participant.pass_turn_to(charlie)

          # Reload participants to get updated state
          other_participant.reload
          initiator_participant.reload

          expect(other_participant.accept_or_counter_turn_id).to eq(charlie.id)
          expect(initiator_participant.accept_or_counter_turn_id).to eq(charlie.id)
        end
      end
    end
  end

  describe "user role assignment" do
    it "assigns correct roles based on context" do
      initiator_participant = agreement_with_participants.agreement_participants.find_by(is_initiator: true)
      other_participant = agreement_with_participants.agreement_participants.find_by(is_initiator: false)

      expect(initiator_participant.user_role).to eq("entrepreneur")
      expect(other_participant.user_role).to eq("co_founder")
    end

    context "for co-founder agreements" do
      let(:co_founder_agreement) { create(:agreement, :co_founder, :with_participants, project:, initiator: alice, other_party: bob) }

      it "assigns co-founder role to non-project-owner" do
        other_participant = co_founder_agreement.agreement_participants.find_by(is_initiator: false)
        expect(other_participant.user_role).to eq("co_founder")
      end
    end
  end

  describe "counter offer integration" do
    let(:original_agreement) { create(:agreement, :with_participants, project:, initiator: alice, other_party: bob) }

    it "links to counter agreement when specified" do
      counter_participant = create(:agreement_participant,
        agreement:,
        user: bob,
        project:,
        counter_agreement: original_agreement,
        is_initiator: true
      )

      expect(counter_participant.counter_agreement).to eq(original_agreement)
    end
  end

  describe "factory integration" do
    it "creates valid participants with factory" do
      participant = create(:agreement_participant, :initiator, agreement:, user: alice, project:)

      expect(participant).to be_valid
      expect(participant).to be_initiator
      expect(participant.user_role).to eq("entrepreneur")
    end

    it "creates mentor participants" do
      participant = create(:agreement_participant, :mentor, agreement:, user: bob, project:)

      expect(participant).to be_valid
      expect(participant.user_role).to eq("mentor")
      expect(participant).not_to be_initiator
    end
  end
end
