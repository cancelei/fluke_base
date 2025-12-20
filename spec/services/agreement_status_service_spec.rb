# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgreementStatusService do
  let(:user) { create(:user, :alice) }
  let(:other_user) { create(:user, :bob) }
  let(:project) { create(:project, user:) }
  let(:agreement) { create(:agreement, :with_participants, project:, initiator: user, other_party: other_user) }

  subject(:service) { described_class.new(agreement) }

  describe '#accept!' do
    context 'when agreement is pending' do
      it 'returns Success with the agreement' do
        result = service.accept!
        expect(result).to be_success
      end

      it 'updates the agreement status to accepted' do
        service.accept!
        expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
      end

      it 'returns the agreement in the success value' do
        result = service.accept!
        expect(unwrap_success(result)).to eq(agreement)
      end
    end

    context 'when agreement is already accepted' do
      before { agreement.update!(status: Agreement::ACCEPTED) }

      it 'returns Failure with invalid_state code' do
        result = service.accept!
        expect(result).to be_failure(:invalid_state)
      end

      it 'includes error message in failure' do
        result = service.accept!
        expect(result).to be_failure_with_message('pending')
      end
    end

    context 'when agreement is rejected' do
      before { agreement.update!(status: Agreement::REJECTED) }

      it 'returns Failure with invalid_state code' do
        result = service.accept!
        expect(result).to be_failure(:invalid_state)
      end
    end
  end

  describe '#reject!' do
    context 'when agreement is pending' do
      it 'returns Success with the agreement' do
        result = service.reject!
        expect(result).to be_success
      end

      it 'updates the agreement status to rejected' do
        service.reject!
        expect(agreement.reload.status).to eq(Agreement::REJECTED)
      end
    end

    context 'when agreement is already accepted' do
      before { agreement.update!(status: Agreement::ACCEPTED) }

      it 'returns Failure with invalid_state code' do
        result = service.reject!
        expect(result).to be_failure(:invalid_state)
      end
    end
  end

  describe '#complete!' do
    context 'when agreement is accepted (active)' do
      before { agreement.update!(status: Agreement::ACCEPTED) }

      it 'returns Success with the agreement' do
        result = service.complete!
        expect(result).to be_success
      end

      it 'updates the agreement status to completed' do
        service.complete!
        expect(agreement.reload.status).to eq(Agreement::COMPLETED)
      end
    end

    context 'when agreement is pending' do
      it 'returns Failure with invalid_state code' do
        result = service.complete!
        expect(result).to be_failure(:invalid_state)
      end

      it 'includes error message about needing to be active' do
        result = service.complete!
        expect(result).to be_failure_with_message('active')
      end
    end
  end

  describe '#cancel!' do
    context 'when agreement is pending' do
      it 'returns Success with the agreement' do
        result = service.cancel!
        expect(result).to be_success
      end

      it 'updates the agreement status to cancelled' do
        service.cancel!
        expect(agreement.reload.status).to eq(Agreement::CANCELLED)
      end
    end

    context 'when agreement is already accepted' do
      before { agreement.update!(status: Agreement::ACCEPTED) }

      it 'returns Failure with invalid_state code' do
        result = service.cancel!
        expect(result).to be_failure(:invalid_state)
      end
    end
  end

  describe '#counter_offer!' do
    let(:counter_agreement) do
      build(:agreement, :with_participants, project:, initiator: other_user, other_party: user)
    end

    context 'when agreement is pending' do
      it 'marks original agreement as countered' do
        service.counter_offer!(counter_agreement)
        expect(agreement.reload.status).to eq(Agreement::COUNTERED)
      end
    end

    context 'when agreement is not pending' do
      before { agreement.update!(status: Agreement::ACCEPTED) }

      it 'returns Failure with invalid_state code' do
        result = service.counter_offer!(counter_agreement)
        expect(result).to be_failure(:invalid_state)
      end
    end
  end
end
