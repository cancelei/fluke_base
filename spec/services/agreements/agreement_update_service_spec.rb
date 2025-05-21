# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Agreements::AgreementUpdateService do
  let(:user) { create(:user) }
  let(:mentor) { create(:user, :mentor) }
  let(:project) { create(:project, user: user) }
  let(:agreement) { create(:agreement, entrepreneur: user, mentor: mentor, project: project) }

  it 'updates the agreement' do
    service = described_class.new(user, agreement, { tasks: 'Updated tasks' })
    updated_agreement, result = service.call
    expect(result).to eq(:success)
    expect(updated_agreement.tasks).to eq('Updated tasks')
  end
end
