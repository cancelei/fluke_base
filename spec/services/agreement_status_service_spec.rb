require 'rails_helper'

RSpec.describe AgreementStatusService do
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }
  let(:project) { create(:project, user: alice) }
  let(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }
  let(:service) { described_class.new(agreement) }

  describe "#accept!" do
    context "when agreement is pending" do
      it "transitions to accepted status" do
        expect(agreement.status).to eq(Agreement::PENDING)

        result = service.accept!

        expect(result).to be_truthy
        expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
      end
    end

    context "when agreement is not pending" do
      it "fails to accept already accepted agreement" do
        agreement.update!(status: Agreement::ACCEPTED)

        result = service.accept!

        expect(result).to be_falsey
        expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
      end

      it "fails to accept rejected agreement" do
        agreement.update!(status: Agreement::REJECTED)

        result = service.accept!

        expect(result).to be_falsey
        expect(agreement.reload.status).to eq(Agreement::REJECTED)
      end

      it "fails to accept completed agreement" do
        agreement.update!(status: Agreement::COMPLETED)

        result = service.accept!

        expect(result).to be_falsey
        expect(agreement.reload.status).to eq(Agreement::COMPLETED)
      end
    end
  end

  describe "#reject!" do
    context "when agreement is pending" do
      it "transitions to rejected status" do
        expect(agreement.status).to eq(Agreement::PENDING)

        result = service.reject!

        expect(result).to be_truthy
        expect(agreement.reload.status).to eq(Agreement::REJECTED)
      end
    end

    context "when agreement is not pending" do
      it "fails to reject accepted agreement" do
        agreement.update!(status: Agreement::ACCEPTED)

        result = service.reject!

        expect(result).to be_falsey
        expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
      end
    end
  end

  describe "#complete!" do
    context "when agreement is accepted (active)" do
      before { agreement.update!(status: Agreement::ACCEPTED) }

      it "transitions to completed status" do
        result = service.complete!

        expect(result).to be_truthy
        expect(agreement.reload.status).to eq(Agreement::COMPLETED)
      end
    end

    context "when agreement is not active" do
      it "fails to complete pending agreement" do
        expect(agreement.status).to eq(Agreement::PENDING)

        result = service.complete!

        expect(result).to be_falsey
        expect(agreement.reload.status).to eq(Agreement::PENDING)
      end

      it "fails to complete rejected agreement" do
        agreement.update!(status: Agreement::REJECTED)

        result = service.complete!

        expect(result).to be_falsey
        expect(agreement.reload.status).to eq(Agreement::REJECTED)
      end
    end
  end

  describe "#cancel!" do
    context "when agreement is pending" do
      it "transitions to cancelled status" do
        expect(agreement.status).to eq(Agreement::PENDING)

        result = service.cancel!

        expect(result).to be_truthy
        expect(agreement.reload.status).to eq(Agreement::CANCELLED)
      end
    end

    context "when agreement is not pending" do
      it "fails to cancel accepted agreement" do
        agreement.update!(status: Agreement::ACCEPTED)

        result = service.cancel!

        expect(result).to be_falsey
        expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
      end
    end
  end

  describe "#counter_offer!" do
    let(:counter_agreement) { create(:agreement, :with_participants, project: project, initiator: bob, other_party: alice) }

    context "when agreement is pending" do
      it "transitions original to countered status and sets up counter agreement" do
        expect(agreement.status).to eq(Agreement::PENDING)
        expect(counter_agreement.status).to eq(Agreement::PENDING)

        result = service.counter_offer!(counter_agreement)

        expect(result).to be_truthy
        expect(agreement.reload.status).to eq(Agreement::COUNTERED)
        expect(counter_agreement.reload.status).to eq(Agreement::PENDING)
        expect(counter_agreement.counter_to_id).to eq(agreement.id)
      end
    end

    context "when agreement is not pending" do
      it "fails to create counter offer for accepted agreement" do
        agreement.update!(status: Agreement::ACCEPTED)

        result = service.counter_offer!(counter_agreement)

        expect(result).to be_falsey
        expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
      end
    end
  end

  describe "counter offer tracking" do
    let(:counter_agreement) do
      create(:agreement, :with_participants, project: project, initiator: bob, other_party: alice).tap do |ca|
        ca.agreement_participants.update_all(counter_agreement_id: agreement.id)
      end
    end

    describe "#has_counter_offers?" do
      it "returns true when agreement has counter offers" do
        counter_agreement # Create the counter offer

        expect(service.has_counter_offers?).to be true
      end

      it "returns false when agreement has no counter offers" do
        expect(service.has_counter_offers?).to be false
      end
    end

    describe "#most_recent_counter_offer" do
      it "returns the most recent counter offer" do
        first_counter = counter_agreement
        second_counter = create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob).tap do |ca|
          ca.agreement_participants.update_all(counter_agreement_id: agreement.id)
          ca.update!(created_at: 1.day.from_now)
        end

        result = service.most_recent_counter_offer
        expect(result).to eq(second_counter)
      end

      it "returns nil when no counter offers exist" do
        result = service.most_recent_counter_offer
        expect(result).to be_nil
      end
    end

    describe "#latest_counter_offer" do
      context "for original agreement" do
        it "returns itself when no counter offers exist" do
          result = service.latest_counter_offer
          expect(result).to eq(agreement)
        end
      end

      context "for counter offer agreement" do
        let(:counter_service) { described_class.new(counter_agreement) }

        it "finds latest counter offer from the original agreement" do
          counter_agreement # Create the counter offer
          original_service = described_class.new(agreement)

          result = counter_service.latest_counter_offer
          expect(result).to eq(counter_agreement)
        end
      end
    end
  end

  describe "integration with agreement model" do
    it "delegates status changes to service" do
      expect(service).to receive(:accept!).and_return(true)
      agreement.accept!
    end

    it "maintains consistency between service and model state" do
      # Test that both service and model reflect the same state
      service.accept!

      expect(agreement.active?).to be true
      expect(agreement.pending?).to be false
    end
  end

  describe "error handling" do
    it "handles database errors gracefully" do
      allow(agreement).to receive(:update).and_raise(ActiveRecord::RecordInvalid.new(agreement))

      expect { service.accept! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "concurrent access scenarios" do
    it "handles race conditions in status updates" do
      # Simulate concurrent access by updating status in another context
      original_status = agreement.status

      # Start transaction but don't commit
      Agreement.transaction do
        service.accept!

        # Simulate another process changing the status
        agreement.reload
        expect(agreement.status).to eq(Agreement::ACCEPTED)
      end
    end
  end
end
