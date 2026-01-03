# frozen_string_literal: true

namespace :e2e do
  desc "Seed test database with FactoryBot data for E2E tests"
  task seed_test_data: :environment do
    unless Rails.env.test?
      puts "❌ This task should only be run in test environment"
      puts "   Use: RAILS_ENV=test bundle exec rake e2e:seed_test_data"
      exit 1
    end

    puts "🌱 Seeding test database with FactoryBot data for E2E tests..."

    # Clear existing data
    puts "  Clearing existing data..."
    TimeLog.destroy_all
    Message.destroy_all
    Conversation.destroy_all
    Meeting.destroy_all
    AgreementParticipant.destroy_all
    Agreement.destroy_all
    Milestone.destroy_all
    Project.destroy_all
    User.destroy_all

    # Create test users using FactoryBot
    puts "  Creating test users..."

    alice = FactoryBot.create(:user,
      email: "alice.entrepreneur@test.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Alice",
      last_name: "Entrepreneur",
      bio: "Serial entrepreneur passionate about Web3 and sustainability"
    )

    bob = FactoryBot.create(:user,
      email: "bob.mentor@test.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Bob",
      last_name: "Mentor",
      bio: "Experienced mentor with 15 years in tech startups",
      years_of_experience: 15.0
    )

    carol = FactoryBot.create(:user,
      email: "carol.cofounder@test.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Carol",
      last_name: "CoFounder",
      bio: "Technical co-founder with expertise in AI/ML"
    )

    frank = FactoryBot.create(:user,
      email: "frank.newbie@test.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Frank",
      last_name: "Newbie",
      bio: "New to the platform, exploring opportunities"
    )

    # Create the legacy e2e@example.com user for existing tests
    e2e_user = FactoryBot.create(:user,
      email: "e2e@example.com",
      password: "Password!123",
      password_confirmation: "Password!123",
      first_name: "E2E",
      last_name: "User"
    )

    puts "  Creating projects..."

    # Alice's projects
    alice_project = FactoryBot.create(:project,
      user: alice,
      name: "DeFi Yield Optimizer",
      description: "AI-powered yield farming protocol",
      stage: Project::PROTOTYPE
    )

    bob_project = FactoryBot.create(:project,
      user: bob,
      name: "HealthTech Analytics",
      description: "AI-driven healthcare analytics platform",
      stage: Project::LAUNCHED
    )

    # Create milestones for projects
    puts "  Creating milestones..."

    alice_milestone = FactoryBot.create(:milestone,
      project: alice_project,
      title: "Complete MVP Development",
      due_date: 30.days.from_now,
      status: Milestone::IN_PROGRESS
    )

    bob_milestone = FactoryBot.create(:milestone,
      project: bob_project,
      title: "Launch Beta Version",
      due_date: 14.days.from_now,
      status: Milestone::PENDING
    )

    puts "  Creating agreements..."

    # Alice seeks mentorship from Bob
    mentorship_agreement = FactoryBot.create(:agreement,
      project: alice_project,
      agreement_type: Agreement::MENTORSHIP,
      payment_type: Agreement::HOURLY,
      hourly_rate: 50,
      weekly_hours: 5,
      start_date: Date.today,
      end_date: 90.days.from_now,
      status: Agreement::ACCEPTED,
      milestone_ids: [alice_milestone.id]
    )

    # Create agreement participants
    FactoryBot.create(:agreement_participant,
      agreement: mentorship_agreement,
      user: alice,
      is_initiator: true
    )

    FactoryBot.create(:agreement_participant,
      agreement: mentorship_agreement,
      user: bob,
      is_initiator: false
    )

    # Carol joins Alice's project as co-founder
    cofounder_agreement = FactoryBot.create(:agreement,
      project: alice_project,
      agreement_type: Agreement::CO_FOUNDER,
      payment_type: Agreement::EQUITY,
      equity_percentage: 20.0,
      weekly_hours: 40,
      start_date: Date.today,
      end_date: 365.days.from_now,
      status: Agreement::ACCEPTED,
      milestone_ids: [alice_milestone.id]
    )

    FactoryBot.create(:agreement_participant,
      agreement: cofounder_agreement,
      user: alice,
      is_initiator: true
    )

    FactoryBot.create(:agreement_participant,
      agreement: cofounder_agreement,
      user: carol,
      is_initiator: false
    )

    puts "  Creating time logs..."

    # Bob logs time for mentorship project
    5.times do |i|
      # Create completed time logs
      started = (i + 1).days.ago.change(hour: 9)
      ended = started + [2.0, 3.0, 2.5, 4.0, 3.5].sample.hours
      hours = ((ended - started) / 3600.0).round(2)

      FactoryBot.create(:time_log,
        project: alice_project,
        milestone: alice_milestone,
        user: bob,
        started_at: started,
        ended_at: ended,
        hours_spent: hours,
        status: "completed",
        manual_entry: false,
        description: "Mentorship session on #{['architecture', 'product strategy', 'team building', 'fundraising'][i % 4]}"
      )
    end

    # Carol logs time for co-founder work
    3.times do |i|
      started = (i + 1).days.ago.change(hour: 9)
      ended = started + [8.0, 7.5, 9.0].sample.hours
      hours = ((ended - started) / 3600.0).round(2)

      FactoryBot.create(:time_log,
        project: alice_project,
        milestone: alice_milestone,
        user: carol,
        started_at: started,
        ended_at: ended,
        hours_spent: hours,
        status: "completed",
        manual_entry: false,
        description: "Development work on #{['backend API', 'frontend features', 'testing'][i % 3]}"
      )
    end

    puts "  Creating conversations and messages..."

    # Conversation between Alice and Bob
    conversation_alice_bob = Conversation.between(alice.id, bob.id)

    FactoryBot.create(:message,
      conversation: conversation_alice_bob,
      user: alice,
      body: "Hi Bob! Thanks for accepting the mentorship agreement. Looking forward to working together!",
      read: true,
      created_at: 2.days.ago
    )

    FactoryBot.create(:message,
      conversation: conversation_alice_bob,
      user: bob,
      body: "Happy to help! Let's schedule our first session this week.",
      read: true,
      created_at: 2.days.ago + 1.hour
    )

    puts "  Creating meetings..."

    # Meeting for mentorship
    FactoryBot.create(:meeting,
      agreement: mentorship_agreement,
      title: "Initial Strategy Session",
      description: "Discuss product roadmap and go-to-market strategy",
      start_time: 2.days.from_now.change(hour: 14),
      end_time: 2.days.from_now.change(hour: 15, min: 30)
    )

    puts "\n✅ E2E test data seeded successfully!"
    puts "\n📊 Summary:"
    puts "   👥 Users: #{User.count}"
    puts "   🚀 Projects: #{Project.count}"
    puts "   📋 Agreements: #{Agreement.count}"
    puts "   🎯 Milestones: #{Milestone.count}"
    puts "   ⏰ Time Logs: #{TimeLog.count}"
    puts "   💬 Messages: #{Message.count}"
    puts "   📅 Meetings: #{Meeting.count}"

    puts "\n🔑 Test Users (all with password: 'password123'):"
    puts "   • alice.entrepreneur@test.com - Project owner"
    puts "   • bob.mentor@test.com - Active mentor"
    puts "   • carol.cofounder@test.com - Co-founder"
    puts "   • frank.newbie@test.com - New user"
    puts "   • e2e@example.com - Legacy test user (password: 'Password!123')"
  end

  desc "Clear E2E test data"
  task clear_test_data: :environment do
    unless Rails.env.test?
      puts "❌ This task should only be run in test environment"
      exit 1
    end

    puts "🧹 Clearing E2E test data..."
    TimeLog.destroy_all
    Message.destroy_all
    Conversation.destroy_all
    Meeting.destroy_all
    AgreementParticipant.destroy_all
    Agreement.destroy_all
    Milestone.destroy_all
    Project.destroy_all
    User.destroy_all
    puts "✅ Test data cleared"
  end
end
