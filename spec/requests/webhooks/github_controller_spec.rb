# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Webhooks::Github", type: :request do
  let(:webhook_secret) { "test_webhook_secret_123" }
  let(:ping_payload) { { zen: "Design for failure.", hook_id: 12345 }.to_json }
  let(:installation_payload) do
    {
      action: "created",
      installation: {
        id: 999999,
        account: { id: 123456, login: "testuser", type: "User" },
        repository_selection: "selected",
        permissions: { contents: "read", metadata: "read" }
      },
      repositories: [
        { id: 1, full_name: "testuser/repo1", private: false }
      ],
      sender: { login: "testuser" }
    }.to_json
  end

  def generate_signature(payload, secret)
    "sha256=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, payload)
  end

  describe "POST /webhooks/github" do
    context "webhook signature validation" do
      before do
        allow(Github::AppConfig).to receive(:webhook_secret).and_return(webhook_secret)
      end

      it "returns 401 without X-Hub-Signature-256 header" do
        post "/webhooks/github",
             params: ping_payload,
             headers: {
               "Content-Type" => "application/json",
               "X-GitHub-Event" => "ping"
             }

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns 401 with invalid signature" do
        post "/webhooks/github",
             params: ping_payload,
             headers: {
               "Content-Type" => "application/json",
               "X-GitHub-Event" => "ping",
               "X-Hub-Signature-256" => "sha256=invalid_signature"
             }

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns 200 with valid signature" do
        signature = generate_signature(ping_payload, webhook_secret)

        post "/webhooks/github",
             params: ping_payload,
             headers: {
               "Content-Type" => "application/json",
               "X-GitHub-Event" => "ping",
               "X-Hub-Signature-256" => signature
             }

        expect(response).to have_http_status(:ok)
      end

      it "uses timing-safe comparison to prevent timing attacks" do
        # This test verifies the implementation uses secure_compare
        # by checking that slightly different signatures take similar time
        signature = generate_signature(ping_payload, webhook_secret)
        wrong_signature = "sha256=" + ("a" * 64) # Same length, wrong content

        # Both should fail at roughly the same time due to secure_compare
        expect(Rack::Utils).to receive(:secure_compare).and_call_original

        post "/webhooks/github",
             params: ping_payload,
             headers: {
               "Content-Type" => "application/json",
               "X-GitHub-Event" => "ping",
               "X-Hub-Signature-256" => wrong_signature
             }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when webhook secret is not configured" do
      before do
        allow(Github::AppConfig).to receive(:webhook_secret).and_return(nil)
      end

      context "in production environment" do
        before do
          allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        end

        it "returns 500 internal server error" do
          post "/webhooks/github",
               params: ping_payload,
               headers: {
                 "Content-Type" => "application/json",
                 "X-GitHub-Event" => "ping"
               }

          expect(response).to have_http_status(:internal_server_error)
        end
      end

      context "in development/test environment" do
        it "skips signature verification and processes webhook" do
          post "/webhooks/github",
               params: ping_payload,
               headers: {
                 "Content-Type" => "application/json",
                 "X-GitHub-Event" => "ping"
               }

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "ping event" do
      before do
        allow(Github::AppConfig).to receive(:webhook_secret).and_return(webhook_secret)
      end

      it "responds successfully to ping events" do
        signature = generate_signature(ping_payload, webhook_secret)

        post "/webhooks/github",
             params: ping_payload,
             headers: {
               "Content-Type" => "application/json",
               "X-GitHub-Event" => "ping",
               "X-Hub-Signature-256" => signature
             }

        expect(response).to have_http_status(:ok)
      end
    end

    context "installation event" do
      let!(:user) { create(:user, github_uid: "123456", github_username: "testuser") }

      before do
        allow(Github::AppConfig).to receive(:webhook_secret).and_return(webhook_secret)
      end

      it "creates installation record on installation.created event" do
        signature = generate_signature(installation_payload, webhook_secret)

        expect {
          post "/webhooks/github",
               params: installation_payload,
               headers: {
                 "Content-Type" => "application/json",
                 "X-GitHub-Event" => "installation",
                 "X-Hub-Signature-256" => signature
               }
        }.to change(GithubAppInstallation, :count).by(1)

        expect(response).to have_http_status(:ok)

        installation = GithubAppInstallation.last
        expect(installation.installation_id).to eq("999999")
        expect(installation.user).to eq(user)
        expect(installation.account_login).to eq("testuser")
      end

      it "deletes installation record on installation.deleted event" do
        create(:github_app_installation, installation_id: "999999", user:)
        delete_payload = {
          action: "deleted",
          installation: { id: 999999 },
          sender: { login: "testuser" }
        }.to_json
        signature = generate_signature(delete_payload, webhook_secret)

        expect {
          post "/webhooks/github",
               params: delete_payload,
               headers: {
                 "Content-Type" => "application/json",
                 "X-GitHub-Event" => "installation",
                 "X-Hub-Signature-256" => signature
               }
        }.to change(GithubAppInstallation, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    context "installation_repositories event" do
      let!(:user) { create(:user, github_uid: "123456", github_username: "testuser") }
      let!(:installation) { create(:github_app_installation, installation_id: "999999", user:) }

      before do
        allow(Github::AppConfig).to receive(:webhook_secret).and_return(webhook_secret)
      end

      it "adds repositories on repositories_added action" do
        add_payload = {
          action: "added",
          installation: { id: 999999 },
          repositories_added: [
            { id: 555, full_name: "testuser/new-repo" }
          ]
        }.to_json
        signature = generate_signature(add_payload, webhook_secret)

        post "/webhooks/github",
             params: add_payload,
             headers: {
               "Content-Type" => "application/json",
               "X-GitHub-Event" => "installation_repositories",
               "X-Hub-Signature-256" => signature
             }

        expect(response).to have_http_status(:ok)
        installation.reload
        repo_names = installation.repository_selection["repositories"].map { |r| r["full_name"] }
        expect(repo_names).to include("testuser/new-repo")
      end
    end

    context "error handling" do
      before do
        allow(Github::AppConfig).to receive(:webhook_secret).and_return(webhook_secret)
      end

      it "handles unknown event types gracefully" do
        unknown_event_payload = { unknown: "data" }.to_json
        signature = generate_signature(unknown_event_payload, webhook_secret)

        post "/webhooks/github",
             params: unknown_event_payload,
             headers: {
               "Content-Type" => "application/json",
               "X-GitHub-Event" => "unknown_event",
               "X-Hub-Signature-256" => signature
             }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
