# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Agreements::AgreementCreationService do
  let(:user) { create(:user) }
  let(:mentor) { create(:user, :mentor) }
  let(:project) { create(:project, user: user) }
  let(:params) { attributes_for(:agreement, project_id: project.id, mentor_id: mentor.id, entrepreneur_id: user.id) }
  let(:session) { {} }

  it 'creates a new agreement' do
    service = described_class.new(user, params, session)
    agreement, result, _ = service.call
    expect(result).to eq(:success)
    expect(agreement).to be_persisted
  end
end
