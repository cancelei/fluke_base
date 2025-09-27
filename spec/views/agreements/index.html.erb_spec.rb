require 'rails_helper'

RSpec.describe "agreements/index.html.erb", type: :view do
  let(:user) { create(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    assign(:query, AgreementsQuery.new(user, {}))
    assign(:my_agreements, Kaminari.paginate_array([]).page(1))
    assign(:other_party_agreements, Kaminari.paginate_array([]).page(1))
  end

  it 'renders the Agreements header and sections' do
    render
    expect(rendered).to include('Agreements')
    expect(rendered).to have_css('#agreement_results')
  end
end
