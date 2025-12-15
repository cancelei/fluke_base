# frozen_string_literal: true

require "rails_helper"

RSpec.describe Milestones::AiEnhanceCommand, type: :command do
  it_behaves_like "a milestone command"

  describe "#execute" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user: user) }
    let(:milestone) { create(:milestone, project: project, description: "Original description") }

    context "with existing milestone" do
      let(:command) do
        build_command(described_class, user: user,
          element_data: {
            projectId: project.id.to_s,
            milestoneId: milestone.id.to_s
          },
          params: {
            milestone: {
              title: milestone.title,
              description: milestone.description
            },
            enhancement_style: "professional"
          })
      end

      before do
        # Stub the background job to avoid actual execution
        allow(MilestoneEnhancementJob).to receive(:perform_later).and_return(true)
      end

      it "creates a milestone enhancement record" do
        expect { command.execute }.to change(MilestoneEnhancement, :count).by(1)
      end

      it "sets enhancement status to processing" do
        command.execute
        enhancement = MilestoneEnhancement.last
        expect(enhancement.status).to eq("processing")
      end

      it "queues the enhancement job" do
        command.execute
        expect(MilestoneEnhancementJob).to have_received(:perform_later)
      end

      it "sets page state for polling" do
        command.execute
        expect(command.state.page["enhancement_id"]).to be_present
        expect(command.state.page["polling_active"]).to eq(true)
      end

      it "updates the AI suggestion frame" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "ai-suggestion-container" }
        expect(stream).to be_present
      end

      it "displays a notice message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:notice]).to include("started")
      end
    end

    context "with direct enhancement (no milestone ID)" do
      let(:command) do
        build_command(described_class, user: user,
          element_data: {
            projectId: project.id.to_s
          },
          params: {
            title: "New Feature",
            description: "Build a new feature",
            enhancement_style: "professional"
          })
      end

      before do
        # Stub the AI enhancement service
        service = instance_double(MilestoneAiEnhancementService)
        allow(MilestoneAiEnhancementService).to receive(:new).and_return(service)
        allow(service).to receive(:augment_description).and_return("Enhanced description")
      end

      it "calls the AI service directly" do
        command.execute
        expect(MilestoneAiEnhancementService).to have_received(:new).with(project)
      end

      it "displays a success message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:notice]).to include("completed")
      end
    end

    context "with empty content" do
      let(:command) do
        build_command(described_class, user: user,
          element_data: {
            projectId: project.id.to_s
          },
          params: {
            title: "",
            description: ""
          })
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("title or description")
      end

      it "does not create an enhancement record" do
        expect { command.execute }.not_to change(MilestoneEnhancement, :count)
      end
    end

    context "when AI service fails" do
      let(:command) do
        build_command(described_class, user: user,
          element_data: {
            projectId: project.id.to_s
          },
          params: {
            title: "New Feature",
            description: "Build a new feature",
            enhancement_style: "professional"
          })
      end

      before do
        service = instance_double(MilestoneAiEnhancementService)
        allow(MilestoneAiEnhancementService).to receive(:new).and_return(service)
        allow(service).to receive(:augment_description).and_raise(StandardError, "Service unavailable")
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("failed")
      end
    end

    context "with different enhancement styles" do
      %w[professional technical creative concise detailed].each do |style|
        it "accepts #{style} enhancement style" do
          allow(MilestoneEnhancementJob).to receive(:perform_later).and_return(true)

          command = build_command(described_class, user: user,
            element_data: {
              projectId: project.id.to_s,
              milestoneId: milestone.id.to_s
            },
            params: {
              milestone: {
                title: milestone.title,
                description: milestone.description
              },
              enhancement_style: style
            })

          command.execute
          enhancement = MilestoneEnhancement.last
          expect(enhancement.enhancement_style).to eq(style)
        end
      end
    end
  end
end
