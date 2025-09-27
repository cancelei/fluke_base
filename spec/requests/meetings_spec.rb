require 'rails_helper'

# TODO: Rewrite this test to properly test nested meetings routes
RSpec.describe "Meetings", type: :request do
  let(:initiator) { create(:user) }
  let(:other) { create(:user) }
  let(:agreement) { create(:agreement, :mentorship, :with_participants, initiator: initiator, other_party: other) }

  before { sign_in initiator }

  it "POST /agreements/:agreement_id/meetings creates meeting" do
    post agreement_meetings_path(agreement), params: { meeting: { title: 'Kickoff', description: 'Discuss scope', start_time: 1.day.from_now, end_time: 1.day.from_now + 1.hour } }
    expect(response).to redirect_to(agreement_path(agreement))
    expect(agreement.meetings.reload.count).to be >= 1
  end
end
