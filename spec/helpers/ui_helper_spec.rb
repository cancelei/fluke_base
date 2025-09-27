require 'rails_helper'

RSpec.describe UiHelper, type: :helper do
  it 'renders status_badge with correct class for accepted' do
    html = helper.status_badge('accepted')
    expect(html).to include('bg-green-100')
    expect(html).to include('Accepted')
  end

  it 'renders collaboration_badge for mentor and co-founder' do
    m = helper.collaboration_badge('mentor')
    c = helper.collaboration_badge('co_founder')
    expect(m).to include('Mentor')
    expect(c).to include('Co founder')
  end

  it 'renders stage_badge with capitalized text' do
    html = helper.stage_badge('idea')
    expect(html).to include('Idea')
  end
end
