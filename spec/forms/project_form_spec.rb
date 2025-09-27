require 'rails_helper'

RSpec.describe ProjectForm, type: :model do
  let(:user) { create(:user) }

  describe '#save' do
    it 'applies default public fields when none selected' do
      form = described_class.new(name: 'New Project', description: 'Something great', user_id: user.id)

      expect(form.save).to be true
      expect(form.project.public_fields).to match_array(Project::DEFAULT_PUBLIC_FIELDS)
    end

    it 'preserves provided public field selections' do
      form = described_class.new(
        name: 'Selective Project',
        description: 'Focused visibility',
        stage: Project::PROTOTYPE,
        public_fields: [ 'name', 'team_size' ],
        user_id: user.id
      )

      expect(form.save).to be true
      expect(form.project.public_fields).to match_array([ 'name', 'team_size' ])
    end
  end
end
