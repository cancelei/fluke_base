# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Agreements Turbo Streams", type: :request do
  let(:user) { create(:user, :alice) }
  let(:other_user) { create(:user, :bob) }
  let(:project) { create(:project, user: user) }
  let(:agreement) { create(:agreement, :with_participants, project: project, initiator: user, other_party: other_user) }
  let(:accepted_agreement) { create(:agreement, :with_participants, :accepted, project: project, initiator: user, other_party: other_user) }

  describe "POST /agreements/:id/accept" do
    before { sign_in other_user }

    context "with turbo_stream format" do
      it "returns turbo stream content type" do
        post accept_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "includes turbo-stream tag in response" do
        post accept_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include("turbo-stream")
      end

      it "updates agreement status to accepted" do
        post accept_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        agreement.reload
        expect(agreement.status).to eq(Agreement::ACCEPTED)
      end
    end

    context "with HTML format" do
      it "redirects to agreement" do
        post accept_agreement_path(agreement)
        expect(response).to redirect_to(agreement)
      end

      it "sets flash notice" do
        post accept_agreement_path(agreement)
        expect(flash[:notice]).to include("accepted")
      end
    end
  end

  describe "POST /agreements/:id/reject" do
    before { sign_in other_user }

    context "with turbo_stream format" do
      it "returns turbo stream content type" do
        post reject_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "includes turbo-stream tag in response" do
        post reject_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include("turbo-stream")
      end

      it "updates agreement status to rejected" do
        post reject_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        agreement.reload
        expect(agreement.status).to eq(Agreement::REJECTED)
      end
    end

    context "with HTML format" do
      it "redirects to agreement" do
        post reject_agreement_path(agreement)
        expect(response).to redirect_to(agreement)
      end
    end
  end

  describe "POST /agreements/:id/complete" do
    before { sign_in user }

    context "with turbo_stream format" do
      it "returns turbo stream content type" do
        post complete_agreement_path(accepted_agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "includes turbo-stream tag in response" do
        post complete_agreement_path(accepted_agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include("turbo-stream")
      end
    end
  end

  describe "POST /agreements/:id/cancel" do
    before { sign_in user }

    context "with turbo_stream format" do
      it "returns turbo stream content type" do
        post cancel_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "includes turbo-stream tag in response" do
        post cancel_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include("turbo-stream")
      end
    end
  end

  describe "Lazy loading sections" do
    before { sign_in user }

    describe "GET /agreements/:id/meetings_section" do
      it "returns turbo stream for meetings frame" do
        get meetings_section_agreement_path(accepted_agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "includes turbo-stream replace action" do
        get meetings_section_agreement_path(accepted_agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include("turbo-stream")
      end

      it "returns success status" do
        get meetings_section_agreement_path(accepted_agreement)
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /agreements/:id/github_section" do
      it "returns turbo stream for github frame" do
        get github_section_agreement_path(accepted_agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "returns success status" do
        get github_section_agreement_path(accepted_agreement)
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /agreements/:id/time_logs_section" do
      it "returns turbo stream for time_logs frame" do
        get time_logs_section_agreement_path(accepted_agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "returns success status" do
        get time_logs_section_agreement_path(accepted_agreement)
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /agreements/:id/counter_offers_section" do
      it "returns turbo stream for counter_offers frame" do
        get counter_offers_section_agreement_path(accepted_agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "returns success status" do
        get counter_offers_section_agreement_path(accepted_agreement)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /agreements with Turbo Frame" do
    before { sign_in user }

    it "returns success for agreement_results frame" do
      get agreements_path, headers: { "Turbo-Frame" => "agreement_results" }
      expect(response).to have_http_status(:success)
    end

    it "returns success for agreements_my frame" do
      get agreements_path, headers: { "Turbo-Frame" => "agreements_my" }
      expect(response).to have_http_status(:success)
    end

    it "returns success for agreements_other frame" do
      get agreements_path, headers: { "Turbo-Frame" => "agreements_other" }
      expect(response).to have_http_status(:success)
    end

    context "with turbo_stream format for filters" do
      it "returns turbo stream content type" do
        get agreements_path(status: "pending"), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "includes turbo-stream update actions" do
        get agreements_path(status: "pending"), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include("turbo-stream")
      end
    end
  end

  describe "GET /agreements/:id with Turbo Stream" do
    before { sign_in user }

    it "returns turbo stream content type" do
      get agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "includes turbo-stream replace action" do
      get agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.body).to include("turbo-stream")
    end
  end

  describe "Authorization with Turbo requests" do
    let(:unauthorized_user) { create(:user) }

    before { sign_in unauthorized_user }

    it "redirects unauthorized access with HTML format" do
      get agreement_path(agreement)
      expect(response).to redirect_to(agreements_path)
    end

    it "returns redirect for unauthorized turbo_stream request" do
      get agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      # Should redirect or return error status for unauthorized access
      expect(response).to redirect_to(agreements_path).or have_http_status(:forbidden)
    end
  end
end
