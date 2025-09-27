# Authentication helpers for tests
module AuthenticationHelpers
  # Sign in user for request specs
  def sign_in_user(user = nil)
    user ||= create(:user)
    sign_in user
    user
  end

  # Create and sign in Alice (consistent test user)
  def sign_in_alice
    alice = create(:user, :alice)
    sign_in alice
    alice
  end

  # Create and sign in Bob (consistent test user)
  def sign_in_bob
    bob = create(:user, :bob)
    sign_in bob
    bob
  end

  # Create a user with specific traits and sign them in
  def create_and_sign_in_user(*traits)
    user = create(:user, *traits)
    sign_in user
    user
  end

  # For controller specs that need authentication
  def authenticate_user!(user = nil)
    user ||= create(:user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    user
  end

  # Create authenticated context for multiple users
  def with_users(alice: true, bob: true)
    users = {}
    users[:alice] = create(:user, :alice) if alice
    users[:bob] = create(:user, :bob) if bob
    users
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :controller
  config.include AuthenticationHelpers, type: :system
end
