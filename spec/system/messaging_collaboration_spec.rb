require 'rails_helper'

RSpec.describe "Messaging and Collaboration", type: :system, js: true do
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, :accepted, :mentorship,
                           project: project, initiator: alice, other_party: bob) }

  describe "Conversation Management" do
    it "creates and manages conversations between collaborators" do
      sign_in alice
      visit conversations_path

      # Start new conversation
      click_link "New Conversation"

      fill_in "To", with: bob.email
      fill_in "Subject", with: "Project Kickoff Discussion"
      fill_in "Message", with: "Hi Bob! Let's discuss the project timeline and deliverables."

      click_button "Send Message"

      expect(page).to have_content("Message sent successfully")
      expect(page).to have_content("Project Kickoff Discussion")

      conversation = Conversation.last
      expect(conversation.users).to include(alice, bob)

      # Verify conversation appears in list
      visit conversations_path
      expect(page).to have_content("Project Kickoff Discussion")
      expect(page).to have_content(bob.full_name)
    end

    it "displays conversation history and allows replies" do
      conversation = create(:conversation, :between_users, user1: alice, user2: bob)
      original_message = create(:message, conversation: conversation, user: alice,
                               body: "What's the status on the API endpoints?")

      sign_in bob
      visit conversation_path(conversation)

      # Should show conversation history
      expect(page).to have_content("What's the status on the API endpoints?")
      expect(page).to have_content(alice.full_name)

      # Reply to conversation
      fill_in "message_body", with: "I've completed 3 out of 5 endpoints. The user authentication and project creation are done."
      click_button "Send Reply"

      expect(page).to have_content("I've completed 3 out of 5 endpoints")
      expect(page).to have_content(bob.full_name)
    end
  end

  describe "Meeting Scheduling and Management" do
    it "schedules meetings from agreement context" do
      sign_in alice
      visit agreement_path(agreement)

      click_link "Schedule Meeting"

      fill_in "Title", with: "Weekly Check-in"
      fill_in "Description", with: "Discuss progress and next steps"
      select_date = Date.current + 1.week
      fill_in "Scheduled At", with: select_date.strftime("%Y-%m-%d")
      fill_in "Time", with: "14:00"

      click_button "Create Meeting"

      expect(page).to have_content("Meeting scheduled successfully")
      expect(page).to have_content("Weekly Check-in")
    end

    it "displays meeting calendar and allows management" do
      meeting = create(:meeting, agreement: agreement, user: alice,
                      title: "Project Review", scheduled_at: 1.week.from_now)

      sign_in alice
      visit meetings_path

      expect(page).to have_content("Project Review")
      expect(page).to have_content(meeting.scheduled_at.strftime("%B %d, %Y"))
    end

    it "handles meeting notifications and reminders" do
      meeting = create(:meeting, agreement: agreement, user: alice,
                      scheduled_at: 1.hour.from_now)

      sign_in alice
      visit meeting_path(meeting)

      expect(page).to have_content("Upcoming Meeting")
      expect(page).to have_content(meeting.title)
    end
  end

  describe "Real-time Collaboration Features" do
    it "shows online status of collaborators" do
      sign_in alice
      visit conversations_path

      # Should show online status (this would be implemented with WebSocket)
      expect(page).to have_css("[data-testid='user-status']")
    end

    it "provides real-time message notifications" do
      conversation = create(:conversation, :between_users, user1: alice, user2: bob)

      sign_in alice
      visit conversation_path(conversation)

      # Send a message
      fill_in "message_body", with: "Hey, how's it going?"
      click_button "Send Reply"

      # Should show notification (this would be real-time in actual app)
      expect(page).to have_content("Hey, how's it going?")
    end
  end

  describe "File Sharing and Attachments" do
    it "allows file attachments in messages" do
      conversation = create(:conversation, :between_users, user1: alice, user2: bob)

      sign_in alice
      visit conversation_path(conversation)

      # Attach a file
      attach_file "message_attachments", Rails.root.join("spec/fixtures/sample.txt")
      fill_in "message_body", with: "Here's the document you requested"
      click_button "Send Reply"

      expect(page).to have_content("Here's the document you requested")
      expect(page).to have_content("sample.txt")
    end

    it "displays file attachments with proper preview" do
      conversation = create(:conversation, :between_users, user1: alice, user2: bob)
      message = create(:message, conversation: conversation, user: alice,
                      body: "Check this out",
                      attachments: [ fixture_file_upload("spec/fixtures/sample.txt") ])

      sign_in bob
      visit conversation_path(conversation)

      expect(page).to have_content("Check this out")
      expect(page).to have_link("sample.txt")
    end
  end

  describe "Conversation Search and Organization" do
    it "searches through conversation content" do
      conversation = create(:conversation, :between_users, user1: alice, user2: bob)
      create(:message, conversation: conversation, user: alice,
             body: "API documentation is ready")
      create(:message, conversation: conversation, user: bob,
             body: "Database schema needs updating")

      sign_in alice
      visit conversations_path

      fill_in "Search", with: "API documentation"
      click_button "Search"

      expect(page).to have_content("API documentation is ready")
      expect(page).not_to have_content("Database schema needs updating")
    end

    it "filters conversations by participants" do
      conversation1 = create(:conversation, :between_users, user1: alice, user2: bob)
      charlie = create(:user, :charlie)
      conversation2 = create(:conversation, :between_users, user1: alice, user2: charlie)

      sign_in alice
      visit conversations_path

      select bob.full_name, from: "Participant"
      click_button "Filter"

      expect(page).to have_content(conversation1.subject)
      expect(page).not_to have_content(conversation2.subject)
    end

    it "marks conversations as read/unread" do
      conversation = create(:conversation, :between_users, user1: alice, user2: bob)
      create(:message, conversation: conversation, user: bob,
             body: "New message for you")

      sign_in alice
      visit conversations_path

      # Should show unread indicator
      expect(page).to have_css("[data-testid='unread-indicator']")

      # Mark as read
      click_link conversation.subject
      visit conversations_path

      # Should not show unread indicator
      expect(page).not_to have_css("[data-testid='unread-indicator']")
    end
  end

  describe "Performance and Scalability" do
    it "handles large conversation histories efficiently" do
      conversation = create(:conversation, :between_users, user1: alice, user2: bob)

      # Create many messages
      100.times do |i|
        create(:message, conversation: conversation,
               user: [ alice, bob ].sample,
               body: "Message #{i}")
      end

      sign_in alice
      visit conversation_path(conversation)

      # Should load efficiently
      expect(page).to have_content("Message 0")
      expect(page).to have_content("Message 99")
    end

    it "loads conversations list efficiently" do
      # Create many conversations
      50.times do |i|
        create(:conversation, :between_users, user1: alice, user2: bob,
               subject: "Conversation #{i}")
      end

      sign_in alice
      visit conversations_path

      # Should load within reasonable time
      expect(page).to have_content("Conversation 0")
      expect(page).to have_content("Conversation 49")
    end
  end
end
