# frozen_string_literal: true

require "rails_helper"

RSpec.describe Github::InstallationTokenService do
  let(:installation_id) { "12345678" }
  let(:jwt_token) { "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.test" }
  let(:installation_token) { "ghs_test_installation_token" }
  let(:token_expires_at) { 1.hour.from_now }

  let(:github_response) do
    double(
      token: installation_token,
      expires_at: token_expires_at,
      permissions: { contents: "read", metadata: "read" },
      repositories: []
    )
  end

  describe ".call" do
    before do
      allow(Github::AppJwtGenerator).to receive(:call).and_return(Dry::Monads::Success(jwt_token))
    end

    context "when generating a new token" do
      let(:octokit_client) { instance_double(Octokit::Client) }

      before do
        allow(Octokit::Client).to receive(:new).with(bearer_token: jwt_token).and_return(octokit_client)
        allow(octokit_client).to receive(:create_app_installation_access_token)
          .with(installation_id)
          .and_return(github_response)
        Rails.cache.clear
      end

      it "generates new token successfully" do
        result = described_class.call(installation_id:, use_cache: false)

        expect(result).to be_success
        expect(result.value![:token]).to eq(installation_token)
      end

      it "includes token metadata in response" do
        result = described_class.call(installation_id:, use_cache: false)

        expect(result.value![:expires_at]).to eq(token_expires_at)
        expect(result.value![:permissions]).to eq({ contents: "read", metadata: "read" })
      end
    end

    context "when caching is enabled" do
      let(:octokit_client) { instance_double(Octokit::Client) }

      before do
        Rails.cache.clear
        allow(Octokit::Client).to receive(:new).with(bearer_token: jwt_token).and_return(octokit_client)
        allow(octokit_client).to receive(:create_app_installation_access_token)
          .with(installation_id)
          .and_return(github_response)
      end

      it "generates token successfully with caching enabled" do
        result = described_class.call(installation_id:, use_cache: true)

        expect(result).to be_success
        expect(result.value![:token]).to eq(installation_token)
      end

      it "includes token expiry in result" do
        result = described_class.call(installation_id:, use_cache: true)

        expect(result.value![:expires_at]).to eq(token_expires_at)
      end

      it "includes generated_at timestamp in result" do
        result = described_class.call(installation_id:, use_cache: true)

        expect(result.value![:generated_at]).to be_within(1.second).of(Time.current)
      end

      it "generates new token when cache is empty" do
        result = described_class.call(installation_id:, use_cache: true)

        expect(result).to be_success
        expect(result.value![:token]).to eq(installation_token)
      end
    end

    context "when JWT generation fails" do
      before do
        allow(Github::AppJwtGenerator).to receive(:call).and_return(
          Dry::Monads::Failure({ error: :jwt_generation_failed, message: "Private key not configured" })
        )
      end

      it "returns failure" do
        result = described_class.call(installation_id:)

        expect(result).to be_failure
      end
    end
  end

  describe ".client_for_installation" do
    let(:octokit_client) { instance_double(Octokit::Client) }

    before do
      allow(Github::AppJwtGenerator).to receive(:call).and_return(Dry::Monads::Success(jwt_token))
      allow(Octokit::Client).to receive(:new).and_return(octokit_client)
      allow(octokit_client).to receive(:create_app_installation_access_token)
        .and_return(github_response)
      Rails.cache.clear
    end

    it "returns an Octokit client with installation token" do
      allow(Octokit::Client).to receive(:new).with(access_token: installation_token).and_return(octokit_client)

      result = described_class.client_for_installation(installation_id)

      expect(result).to eq(octokit_client)
    end

    it "returns nil when token generation fails" do
      allow(Github::AppJwtGenerator).to receive(:call).and_return(
        Dry::Monads::Failure({ error: :jwt_generation_failed })
      )

      result = described_class.client_for_installation(installation_id)

      expect(result).to be_nil
    end
  end

  describe ".client_for_repo" do
    let(:user) { create(:user) }
    let(:installation) { create(:github_app_installation, installation_id:, user:) }
    let(:octokit_client) { instance_double(Octokit::Client) }

    before do
      allow(Github::AppJwtGenerator).to receive(:call).and_return(Dry::Monads::Success(jwt_token))
      allow(Octokit::Client).to receive(:new).and_return(octokit_client)
      allow(octokit_client).to receive(:create_app_installation_access_token)
        .and_return(github_response)
      Rails.cache.clear
    end

    it "returns client for repository via user's installations" do
      allow(user).to receive(:installation_for_repo).with("owner/repo").and_return(installation)
      allow(Octokit::Client).to receive(:new).with(access_token: installation_token).and_return(octokit_client)

      result = described_class.client_for_repo(user:, repo_full_name: "owner/repo")

      expect(result).to eq(octokit_client)
    end

    it "returns nil when user has no installation for repo" do
      allow(user).to receive(:installation_for_repo).with("other/repo").and_return(nil)

      result = described_class.client_for_repo(user:, repo_full_name: "other/repo")

      expect(result).to be_nil
    end
  end
end
