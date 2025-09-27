class TestOnly::SessionsController < ApplicationController
  before_action :ensure_test_environment
  skip_before_action :authenticate_user!
  skip_forgery_protection

  # Creates (or finds) a user and signs them in using Devise.
  # Params: email, password
  def create
    email = (params[:email] || "e2e@example.com").to_s.downcase
    password = (params[:password] || default_password)

    user = User.find_by(email: email)
    unless user
      user = User.new(
        email: email,
        password: password,
        password_confirmation: password,
        first_name: "E2E",
        last_name: "User"
      )
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
      user.save!
    end

    # Ensure password is set correctly for re-login
    if user.respond_to?(:valid_password?) && !user.valid_password?(password)
      user.password = password
      user.password_confirmation = password
      user.save!
    end

    sign_in(user)

    respond_to do |format|
      format.html { redirect_to root_path, notice: "Signed in for E2E" }
      format.json { render json: { ok: true, user_id: user.id } }
    end
  end

  private

  def ensure_test_environment
    head :not_found unless Rails.env.test?
  end

  def default_password
    "Password!123"
  end
end
