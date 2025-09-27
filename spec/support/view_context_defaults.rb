# Default stubs for view specs to avoid brittle assumptions about controller context
RSpec.configure do |config|
  config.before(:each, type: :view) do
    # Make current_user nil by default; views relying on it should handle nil safely
    allow(view).to receive(:current_user).and_return(nil)
  end
end
