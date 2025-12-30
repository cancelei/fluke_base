# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookDispatchable, type: :model do
  # Use EnvironmentVariable as test subject since it includes WebhookDispatchable
  let(:project) { create(:project) }
  let(:user) { project.user }
  let(:env_var) do
    create(
      :environment_variable,
      project: project,
      created_by: user,
      key: "TEST_VAR",
      environment: "development"
    )
  end

  describe "webhook_events configuration" do
    it "stores event mappings" do
      expect(EnvironmentVariable._webhook_events).to include(
        "create" => "env.created",
        "update" => "env.updated",
        "destroy" => "env.deleted"
      )
    end
  end

  describe "after_commit callbacks" do
    context "when no webhook subscriptions exist" do
      it "does not raise errors on create" do
        expect {
          create(:environment_variable, project: project, created_by: user, key: "NEW_VAR")
        }.not_to raise_error
      end

      it "does not raise errors on update" do
        expect {
          env_var.update!(description: "Updated description")
        }.not_to raise_error
      end

      it "does not raise errors on destroy" do
        expect {
          env_var.destroy!
        }.not_to raise_error
      end
    end

    context "when webhook subscriptions exist" do
      let!(:api_token) { create(:api_token, user: user) }
      let!(:subscription) do
        create(
          :webhook_subscription,
          project: project,
          api_token: api_token,
          events: ["env.created", "env.updated", "env.deleted"],
          callback_url: "https://example.com/webhooks"
        )
      end

      it "dispatches webhook on create" do
        expect {
          create(:environment_variable, project: project, created_by: user, key: "WEBHOOK_VAR")
        }.to change(WebhookDelivery, :count).by(1)
      end

      it "dispatches webhook on update" do
        env_var # Trigger lazy creation (causes 1 webhook)
        expect {
          env_var.update!(description: "Updated")
        }.to change(WebhookDelivery, :count).by(1)
      end

      it "dispatches webhook on destroy" do
        env_var # Trigger lazy creation (causes 1 webhook)
        expect {
          env_var.destroy!
        }.to change(WebhookDelivery, :count).by(1)
      end

      it "creates delivery with correct event type" do
        create(:environment_variable, project: project, created_by: user, key: "EVENT_TYPE_VAR")
        delivery = WebhookDelivery.last
        expect(delivery.event_type).to eq("env.created")
      end

      it "creates delivery with payload" do
        create(:environment_variable, project: project, created_by: user, key: "PAYLOAD_VAR")
        delivery = WebhookDelivery.last
        expect(delivery.payload).to include("event" => "env.created", "project_id" => project.id)
      end
    end
  end
end
