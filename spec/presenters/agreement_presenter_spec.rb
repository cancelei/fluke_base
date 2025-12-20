require 'rails_helper'

RSpec.describe AgreementPresenter do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let(:agreement) { create(:agreement, :with_participants, :mentorship, project:, initiator: alice, other_party: bob) }
  subject(:presenter) { described_class.new(agreement) }

  it 'renders status badge HTML containing status' do
    agreement.update!(status: Agreement::PENDING)
    html = presenter.status_badge
    expect(html).to include(Agreement::PENDING)
  end

  it 'formats payment details via service' do
    agreement.update!(payment_type: Agreement::HOURLY, hourly_rate: 50, weekly_hours: 10)
    expect(presenter.formatted_payment_details).to match(/50/)
  end

  it 'computes duration and total commitment display' do
    agreement.update!(start_date: Date.current, end_date: 4.weeks.from_now.to_date, weekly_hours: 5)
    expect(presenter.duration_display).to match(/days|weeks/)
    expect(presenter.total_commitment_display).to include('hours/week')
  end

  it 'enforces can_be_* checks based on status and participants' do
    agreement.update!(status: Agreement::PENDING)
    expect(presenter.can_be_accepted_by?(bob)).to be true
    expect(presenter.can_be_cancelled_by?(alice)).to be true
  end
end
