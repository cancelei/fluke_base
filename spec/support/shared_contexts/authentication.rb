# frozen_string_literal: true

RSpec.shared_context 'authenticated user' do
  let(:user) { create(:user) }
  before { sign_in user }
end

RSpec.shared_context 'with project' do
  include_context 'authenticated user'
  let(:project) { create(:project, user:) }
end

RSpec.shared_context 'active agreement context' do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) do
    create(:agreement, :with_participants,
           project:,
           initiator: alice,
           other_party: bob,
           status: Agreement::ACCEPTED)
  end

  before { sign_in alice }
end
