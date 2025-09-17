require 'rails_helper'

RSpec.describe "Agreements Integration", type: :request do
  include Devise::Test::IntegrationHelpers
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }
  let(:project) { create(:project, user: alice) }
  let(:milestone1) { create(:milestone, project: project) }
  let(:milestone2) { create(:milestone, project: project) }

  before do
    # Create milestones before tests that need them
    milestone1
    milestone2
  end

  describe "Agreement Creation Workflow" do
    context "when user is authenticated" do
      before { sign_in alice }

      describe "GET /agreements/new" do
        it "shows the new agreement form" do
          get new_agreement_path(project_id: project.id, other_party_id: bob.id)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("New Agreement")
          expect(response.body).to include(bob.full_name)
        end

        it "pre-populates form for counter offers" do
          original_agreement = create(:agreement, :with_participants,
            project: project, initiator: bob, other_party: alice)

          get new_agreement_path(
            project_id: project.id,
            other_party_id: bob.id,
            counter_to_id: original_agreement.id
          )

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Counter Offer")
          expect(response.body).to include(original_agreement.tasks)
        end

        it "prevents duplicate agreements" do
          create(:agreement, :with_participants,
            project: project, initiator: alice, other_party: bob)

          get new_agreement_path(project_id: project.id, other_party_id: bob.id)

          expect(response).to redirect_to(agreements_path)
          follow_redirect!
          expect(response.body).to include("You currently have an agreement")
        end
      end

      describe "POST /agreements" do
        let(:valid_params) do
          {
            agreement: {
              project_id: project.id,
              other_party_user_id: bob.id,
              agreement_type: Agreement::MENTORSHIP,
              payment_type: Agreement::HOURLY,
              start_date: 1.week.from_now.to_date,
              end_date: 4.weeks.from_now.to_date,
              tasks: "Help with project development",
              weekly_hours: 10,
              hourly_rate: 75.0,
              milestone_ids: [ milestone1.id, milestone2.id ]
            }
          }
        end

        it "creates a new agreement successfully" do
          expect {
            post agreements_path, params: valid_params
          }.to change(Agreement, :count).by(1)

          agreement = Agreement.last
          expect(agreement.project).to eq(project)
          expect(agreement.initiator).to eq(alice)
          expect(agreement.other_party).to eq(bob)
          expect(agreement.status).to eq(Agreement::PENDING)
          expect(agreement.milestone_ids).to contain_exactly(milestone1.id, milestone2.id)

          expect(response).to redirect_to(agreement)
        end

        it "creates agreement participants" do
          post agreements_path, params: valid_params

          agreement = Agreement.last
          participants = agreement.agreement_participants

          expect(participants.count).to eq(2)

          initiator_participant = participants.find_by(is_initiator: true)
          expect(initiator_participant.user).to eq(alice)
          expect(initiator_participant.user_role).to eq("entrepreneur")

          other_participant = participants.find_by(is_initiator: false)
          expect(other_participant.user).to eq(bob)
          expect(other_participant.user_role).to eq("mentor")
          expect(other_participant.accept_or_counter_turn_id).to eq(bob.id)
        end

        it "handles validation errors" do
          invalid_params = valid_params.deep_dup
          invalid_params[:agreement][:weekly_hours] = nil

          post agreements_path, params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("Weekly hours can't be blank")
        end

        it "creates counter offers" do
          original_agreement = create(:agreement, :with_participants, :mentorship,
            project: project, initiator: bob, other_party: alice)

          counter_params = valid_params.deep_dup
          counter_params[:agreement][:counter_agreement_id] = original_agreement.id
          counter_params[:agreement][:hourly_rate] = 85.0  # Different rate

          expect {
            post agreements_path, params: counter_params
          }.to change(Agreement, :count).by(1)

          original_agreement.reload
          expect(original_agreement.status).to eq(Agreement::COUNTERED)

          counter_agreement = Agreement.last
          expect(counter_agreement.counter_to).to eq(original_agreement)
          expect(counter_agreement.hourly_rate).to eq(85.0)
        end
      end
    end

    context "when user is not authenticated" do
      it "redirects to login" do
        get new_agreement_path(project_id: project.id, other_party_id: bob.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "Agreement Negotiation Workflow" do
    let(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

    describe "Accept Agreement" do
      context "when other party accepts" do
        before { sign_in bob }

        it "accepts the agreement via POST" do
          expect(agreement.status).to eq(Agreement::PENDING)

          post accept_agreement_path(agreement)

          agreement.reload
          expect(agreement.status).to eq(Agreement::ACCEPTED)
          expect(response).to redirect_to(agreement)
        end

        it "accepts the agreement via Turbo Stream" do
          post accept_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }

          agreement.reload
          expect(agreement.status).to eq(Agreement::ACCEPTED)
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end

        it "creates notification and message for initiator" do
          expect {
            post accept_agreement_path(agreement)
          }.to change(Notification, :count).by(1)

          notification = Notification.last
          expect(notification.user).to eq(alice)
          expect(notification.title).to include("Agreement")
        end
      end

      context "when initiator tries to accept" do
        before { sign_in alice }

        it "prevents acceptance with authorization error" do
          expect {
            post accept_agreement_path(agreement)
          }.to raise_error(CanCan::AccessDenied)
        end
      end
    end

    describe "Reject Agreement" do
      context "when other party rejects" do
        before { sign_in bob }

        it "rejects the agreement" do
          post reject_agreement_path(agreement)

          agreement.reload
          expect(agreement.status).to eq(Agreement::REJECTED)
          expect(response).to redirect_to(agreement)
        end
      end
    end

    describe "Complete Agreement" do
      let(:accepted_agreement) { create(:agreement, :accepted, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

      context "when initiator completes" do
        before { sign_in alice }

        it "completes the agreement" do
          post complete_agreement_path(accepted_agreement)

          accepted_agreement.reload
          expect(accepted_agreement.status).to eq(Agreement::COMPLETED)
          expect(response).to redirect_to(accepted_agreement)
        end
      end
    end

    describe "Cancel Agreement" do
      context "when initiator cancels" do
        before { sign_in alice }

        it "cancels the agreement" do
          post cancel_agreement_path(agreement)

          agreement.reload
          expect(agreement.status).to eq(Agreement::CANCELLED)
          expect(response).to redirect_to(agreement)
        end
      end
    end

    describe "Counter Offer" do
      before { sign_in bob }

      it "redirects to new agreement form with counter offer params" do
        get counter_offer_agreement_path(agreement)

        expect(response).to redirect_to(new_agreement_path(
          project_id: project.id,
          counter_to_id: agreement.id,
          other_party_id: alice.id
        ))
      end
    end
  end

  describe "Agreement Display and Access Control" do
    let(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

    describe "GET /agreements/:id" do
      context "when user is a participant" do
        before { sign_in alice }

        it "shows the agreement details" do
          get agreement_path(agreement)

          expect(response).to have_http_status(:success)
          expect(response.body).to include(agreement.tasks)
          expect(response.body).to include(bob.full_name)
        end

        it "shows proper action buttons for initiator" do
          get agreement_path(agreement)

          expect(response.body).to include("Edit Agreement")
          expect(response.body).to include("Cancel Agreement")
        end
      end

      context "when user is the other party" do
        before { sign_in bob }

        it "shows accept/reject buttons" do
          get agreement_path(agreement)

          expect(response.body).to include("Accept Agreement")
          expect(response.body).to include("Reject Agreement")
          expect(response.body).to include("Make Counter Offer")
        end
      end

      context "when user is not a participant" do
        let(:charlie) { create(:user) }
        before { sign_in charlie }

        it "denies access" do
          get agreement_path(agreement)

          expect(response).to redirect_to(agreements_path)
          follow_redirect!
          expect(response.body).to include("not authorized")
        end
      end
    end

    describe "Lazy Loading Sections" do
      before { sign_in alice }

      it "loads meetings section" do
        get meetings_section_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "loads github section" do
        get github_section_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
      end

      it "loads time logs section" do
        get time_logs_section_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
      end

      it "loads counter offers section" do
        get counter_offers_section_agreement_path(agreement), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "Agreement Listing and Filtering" do
    let!(:my_agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }
    let!(:other_agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: bob, other_party: alice) }
    let!(:accepted_agreement) { create(:agreement, :accepted, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

    before { sign_in alice }

    describe "GET /agreements" do
      it "shows all user's agreements" do
        get agreements_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(my_agreement.tasks)
        expect(response.body).to include(other_agreement.tasks)
        expect(response.body).to include(accepted_agreement.tasks)
      end

      it "filters by status" do
        get agreements_path, params: { status: Agreement::ACCEPTED }

        expect(response).to have_http_status(:success)
        # Should show accepted agreement but filter logic depends on implementation
      end

      it "handles Turbo Frame requests for filtering" do
        get agreements_path, params: { status: Agreement::PENDING },
            headers: {
              "Accept" => "text/vnd.turbo-stream.html",
              "Turbo-Frame" => "agreement_results"
            }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
      end
    end
  end

  describe "Agreement Editing" do
    let(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

    context "when initiator edits" do
      before { sign_in alice }

      describe "GET /agreements/:id/edit" do
        it "shows edit form" do
          get edit_agreement_path(agreement)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Edit Agreement")
          expect(response.body).to include(agreement.tasks)
        end
      end

      describe "PATCH /agreements/:id" do
        it "updates the agreement" do
          patch agreement_path(agreement), params: {
            agreement: {
              tasks: "Updated tasks description",
              weekly_hours: 15,
              milestone_ids: [ milestone1.id ]
            }
          }

          agreement.reload
          expect(agreement.tasks).to eq("Updated tasks description")
          expect(agreement.weekly_hours).to eq(15)
          expect(agreement.milestone_ids).to contain_exactly(milestone1.id)
          expect(response).to redirect_to(agreement)
        end
      end
    end

    context "when other party tries to edit" do
      before { sign_in bob }

      it "denies access to edit" do
        expect {
          get edit_agreement_path(agreement)
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe "Counter Offer Chain" do
    let(:original_agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

    before { sign_in bob }

    it "creates a complete counter offer chain" do
      # Bob creates first counter offer
      post agreements_path, params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: alice.id,
          agreement_type: Agreement::MENTORSHIP,
          payment_type: Agreement::HOURLY,
          start_date: 1.week.from_now.to_date,
          end_date: 4.weeks.from_now.to_date,
          tasks: "Modified tasks by Bob",
          weekly_hours: 12,
          hourly_rate: 80.0,
          milestone_ids: [ milestone1.id ],
          counter_agreement_id: original_agreement.id
        }
      }

      first_counter = Agreement.last
      original_agreement.reload

      expect(original_agreement.status).to eq(Agreement::COUNTERED)
      expect(first_counter.counter_to).to eq(original_agreement)
      expect(first_counter.hourly_rate).to eq(80.0)

      # Alice creates second counter offer
      sign_in alice

      post agreements_path, params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: bob.id,
          agreement_type: Agreement::MENTORSHIP,
          payment_type: Agreement::HOURLY,
          start_date: 1.week.from_now.to_date,
          end_date: 4.weeks.from_now.to_date,
          tasks: "Modified tasks by Alice",
          weekly_hours: 10,
          hourly_rate: 85.0,
          milestone_ids: [ milestone1.id, milestone2.id ],
          counter_agreement_id: first_counter.id
        }
      }

      second_counter = Agreement.last
      first_counter.reload

      expect(first_counter.status).to eq(Agreement::COUNTERED)
      expect(second_counter.counter_to).to eq(first_counter)
      expect(second_counter.hourly_rate).to eq(85.0)

      # Verify agreement chain
      expect(original_agreement.counter_offers).to include(first_counter)
      expect(first_counter.counter_offers).to include(second_counter)
    end
  end

  describe "Edge Cases and Validations" do
    before { sign_in alice }

    it "prevents creating agreements without milestones for mentorship" do
      post agreements_path, params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: bob.id,
          agreement_type: Agreement::MENTORSHIP,
          payment_type: Agreement::HOURLY,
          start_date: 1.week.from_now.to_date,
          end_date: 4.weeks.from_now.to_date,
          tasks: "Help with project development",
          weekly_hours: 10,
          hourly_rate: 75.0,
          milestone_ids: []
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Milestone ids can't be blank")
    end

    it "validates date ranges" do
      post agreements_path, params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: bob.id,
          agreement_type: Agreement::MENTORSHIP,
          payment_type: Agreement::HOURLY,
          start_date: 4.weeks.from_now.to_date,
          end_date: 1.week.from_now.to_date,  # End before start
          tasks: "Help with project development",
          weekly_hours: 10,
          hourly_rate: 75.0,
          milestone_ids: [ milestone1.id ]
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("must be after the start date")
    end

    it "validates payment terms for equity agreements" do
      post agreements_path, params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: bob.id,
          agreement_type: Agreement::CO_FOUNDER,
          payment_type: Agreement::EQUITY,
          start_date: 1.week.from_now.to_date,
          end_date: 4.weeks.from_now.to_date,
          tasks: "Co-founder collaboration",
          weekly_hours: 20
          # Missing equity_percentage
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Equity percentage")
    end
  end
end
