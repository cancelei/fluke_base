require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the AgreementsHelper. For example:
#
# describe AgreementsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe AgreementsHelper, type: :helper do
  describe '#fetch_initiator_data' do
    let(:user) { create(:user, first_name: 'Alice', last_name: 'Smith') }

    it 'returns [name, role] when meta has id and role' do
      meta = { 'id' => user.id, 'role' => 'entrepreneur' }
      expect(helper.fetch_initiator_data(meta)).to eq([ user.full_name, 'entrepreneur' ])
    end

    it 'returns nil when meta is blank' do
      expect(helper.fetch_initiator_data(nil)).to be_nil
    end

    it 'returns [nil, role] when user not found' do
      meta = { 'id' => 999_999, 'role' => 'mentor' }
      expect(helper.fetch_initiator_data(meta)).to eq([ nil, 'mentor' ])
    end
  end
end
