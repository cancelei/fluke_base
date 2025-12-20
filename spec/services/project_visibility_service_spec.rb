require 'rails_helper'

RSpec.describe ProjectVisibilityService do
  let(:owner) { create(:user) }
  let(:collaborator) { create(:user) }
  let(:stranger) { create(:user) }
  let(:project) do
    create(:project,
           user: owner,
           name: 'Visible Project',
           description: 'Hidden content',
           public_fields: ['name'])
  end
  let(:service) { described_class.new(project) }

  before do
    create(:agreement, :with_participants, :mentorship,
           project:,
           initiator: owner,
           other_party: collaborator,
           status: Agreement::ACCEPTED)
  end

  describe '#field_public?' do
    it 'returns true when the field is marked public' do
      expect(service.field_public?(:name)).to be true
    end

    it 'returns false when the field is not marked public' do
      expect(service.field_public?(:description)).to be false
    end

    it 'returns false when public_fields is empty' do
      project.update_column(:public_fields, [])  # Test with empty array
      expect(service.field_public?(:name)).to be false
    end
  end

  describe '#field_visible_to_user?' do
    it 'always allows the project owner' do
      expect(service.field_visible_to_user?(:description, owner)).to be true
    end

    it 'allows collaborators with agreements' do
      expect(service.field_visible_to_user?(:description, collaborator)).to be true
    end

    it 'allows strangers to see public fields only' do
      expect(service.field_visible_to_user?(:name, stranger)).to be true
      expect(service.field_visible_to_user?(:description, stranger)).to be false
    end
  end

  describe '#get_field_value' do
    it 'returns the value when visible to the user' do
      expect(service.get_field_value(:name, stranger)).to eq('Visible Project')
    end

    it 'returns nil when the field is hidden' do
      expect(service.get_field_value(:description, stranger)).to be_nil
    end
  end

  describe '.batch_check_access' do
    let(:second_project) { create(:project, user: owner, public_fields: ['name']) }
    let(:second_collaborator) { create(:user) }

    before do
      create(:agreement, :with_participants, :mentorship,
             project: second_project,
             initiator: owner,
             other_party: second_collaborator,
             status: Agreement::ACCEPTED)
    end

    it 'maps project ids to collaborator user ids' do
      access_map = described_class.batch_check_access([project, second_project], [collaborator, second_collaborator])

      expect(access_map[project.id]).to include(collaborator.id)
      expect(access_map[second_project.id]).to include(second_collaborator.id)
    end
  end
end
