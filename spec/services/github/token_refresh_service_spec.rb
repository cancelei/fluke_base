# frozen_string_literal: true

require "rails_helper"

RSpec.describe Github::TokenRefreshService do
  let(:user) do
    create(:user,
           github_refresh_token: "ghr_test_refresh_token",
           github_user_access_token: "ghu_old_access_token",
           github_token_expires_at: 1.hour.ago,
           github_refresh_token_expires_at: 5.months.from_now)
  end

  let(:successful_response) do
    {
      access_token: "ghu_new_access_token",
      refresh_token: "ghr_new_refresh_token",
      expires_in: 28800, # 8 hours
      refresh_token_expires_in: 15897600 # ~6 months
    }
  end

  describe ".call" do
    context "when refresh token is valid" do
      before do
        allow(HTTParty).to receive(:post).and_return(
          double(body: successful_response.to_json)
        )
        allow(Github::AppConfig).to receive(:client_id).and_return("test_client_id")
        allow(Github::AppConfig).to receive(:client_secret).and_return("test_client_secret")
      end

      it "refreshes expired access tokens" do
        result = described_class.call(user:)

        expect(result).to be_success
        expect(result.value!).to eq("ghu_new_access_token")
      end

      it "updates both access and refresh tokens" do
        described_class.call(user:)

        user.reload
        expect(user.github_user_access_token).to eq("ghu_new_access_token")
        expect(user.github_refresh_token).to eq("ghr_new_refresh_token")
      end

      it "updates token expiry times" do
        before_time = Time.current
        described_class.call(user:)
        after_time = Time.current

        user.reload
        # Token expires in 8 hours (28800 seconds) from the time of the call
        expect(user.github_token_expires_at).to be_between(before_time + 28800.seconds, after_time + 28801.seconds)
      end
    end

    context "when user has no refresh token" do
      let(:user) { create(:user, github_refresh_token: nil) }

      it "returns failure with :no_refresh_token code" do
        result = described_class.call(user:)

        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:no_refresh_token)
      end
    end

    context "when refresh token is expired" do
      let(:user) do
        create(:user,
               github_refresh_token: "ghr_old_token",
               github_user_access_token: "ghu_old_token",
               github_refresh_token_expires_at: 1.day.ago)
      end

      it "returns failure with :refresh_token_expired code" do
        result = described_class.call(user:)

        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:refresh_token_expired)
      end

      it "invalidates the GitHub connection" do
        described_class.call(user:)

        user.reload
        expect(user.github_user_access_token).to be_nil
        expect(user.github_token_expires_at).to be_nil
      end
    end

    context "when GitHub returns expired token error" do
      before do
        allow(HTTParty).to receive(:post).and_return(
          double(body: { error: "bad_refresh_token", error_description: "The refresh token has expired" }.to_json)
        )
        allow(Github::AppConfig).to receive(:client_id).and_return("test_client_id")
        allow(Github::AppConfig).to receive(:client_secret).and_return("test_client_secret")
      end

      it "returns failure with :refresh_token_expired code" do
        result = described_class.call(user:)

        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:refresh_token_expired)
      end

      it "invalidates the GitHub connection" do
        described_class.call(user:)

        user.reload
        expect(user.github_user_access_token).to be_nil
      end
    end

    context "when GitHub returns other error" do
      before do
        allow(HTTParty).to receive(:post).and_return(
          double(body: { error: "invalid_request", error_description: "Something went wrong" }.to_json)
        )
        allow(Github::AppConfig).to receive(:client_id).and_return("test_client_id")
        allow(Github::AppConfig).to receive(:client_secret).and_return("test_client_secret")
      end

      it "returns failure with :refresh_failed code" do
        result = described_class.call(user:)

        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:refresh_failed)
        expect(result.failure[:message]).to include("Something went wrong")
      end
    end

    context "when decryption fails" do
      before do
        allow(user).to receive(:safe_github_refresh_token)
          .and_raise(ActiveRecord::Encryption::Errors::Decryption.new("Decryption failed"))
      end

      it "returns failure with :decryption_error code" do
        result = described_class.call(user:)

        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:decryption_error)
      end
    end
  end
end
