# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Agreements::AgreementStateChangeService do
  let(:user) { create(:user) }
  let(:mentor) { create(:user, :mentor) }
  let(:project) { create(:project, user: user) }
  let(:agreement) { create(:agreement, entrepreneur: user, mentor: mentor, project: project) }

  it 'accepts an agreement' do
    service = described_class.new(user, agreement, :accept)
    success, result = service.call
    expect(success).to be_truthy
    expect(result).to eq(:success)
  end

  it 'rejects an agreement' do
    service = described_class.new(user, agreement, :reject)
    success, result = service.call
    expect(success).to be_truthy
    expect(result).to eq(:success)
  end
end
