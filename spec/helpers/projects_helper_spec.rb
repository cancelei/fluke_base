require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the ProjectsHelper. For example:
#
# describe ProjectsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ProjectsHelper, type: :helper do
  let(:owner) { create(:user) }
  let(:viewer) { create(:user) }
  let(:project) { create(:project, user: owner, name: 'Secret Project', description: 'Top secret') }

  describe '#field_public?' do
    it 'delegates to project.field_public?' do
      expect(project).to receive(:field_public?).with('name').and_return(true)
      expect(helper.field_public?(project, :name)).to be true
    end
  end

  describe '#field_visible_to_user?' do
    it 'delegates to project.visible_to_user?' do
      expect(project).to receive(:visible_to_user?).with('name', viewer).and_return(false)
      expect(helper.field_visible_to_user?(project, :name, viewer)).to be false
    end
  end

  describe '#display_project_name' do
    it 'shows real name when visible' do
      allow(project).to receive(:visible_to_user?).with('name', viewer).and_return(true)
      expect(helper.display_project_name(project, viewer)).to eq('Secret Project')
    end

    it 'masks name when not visible' do
      allow(project).to receive(:visible_to_user?).with('name', viewer).and_return(false)
      masked = helper.display_project_name(project, viewer)
      expect(masked).to match(/Project #\d+/)
    end
  end
end
