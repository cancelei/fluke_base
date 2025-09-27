require 'rails_helper'

RSpec.describe AvatarService do
  let(:user) { create(:user, first_name: 'Taylor', last_name: 'Swift') }
  subject(:service) { described_class.new(user) }

  describe '#initials' do
    it 'returns uppercase initials' do
      expect(service.initials).to eq('TS')
    end
  end

  describe '#url' do
    context 'when the user has an attached avatar' do
      before do
        user.avatar.attach(
          io: StringIO.new('fake data'),
          filename: 'avatar.png',
          content_type: 'image/png'
        )
      end

      it 'returns the attachment' do
        expect(service.url).to eq(user.avatar)
      end
    end

    context 'when the user does not have an avatar attached' do
      it 'returns a generated data URL containing the initials' do
        data_url = service.url

        expect(data_url).to start_with('data:image/svg+xml;base64,')
        decoded = Base64.decode64(data_url.split(',').last)
        expect(decoded).to include('TS')
      end
    end
  end
end
