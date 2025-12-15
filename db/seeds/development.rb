# Enhanced Flukebase Demo Seed File
# Creates realistic data with predictable scenarios for easier testing

require 'faker'

# Note: Role system has been removed - all users are community members

# Create demo data in development and staging environments
if Rails.env.development? || Rails.env.staging?
  puts "🚀 Creating enhanced demo data with test scenarios for #{Rails.env} environment..."

  # Clear existing data to avoid conflicts (only in development)
  if Rails.env.development?
    puts "Clearing existing data..."
    TimeLog.destroy_all
    Message.destroy_all
    Conversation.destroy_all
    Meeting.destroy_all
    AgreementParticipant.destroy_all
    Agreement.destroy_all
    Milestone.destroy_all
    Project.destroy_all
    User.destroy_all
  else
    # In staging, only clear if database is empty or if explicitly requested
    if User.count == 0 || ENV['FORCE_SEED'] == 'true'
      puts "Database appears empty or FORCE_SEED=true, clearing existing data..."
      TimeLog.destroy_all
      Message.destroy_all
      Conversation.destroy_all
      Meeting.destroy_all
      AgreementParticipant.destroy_all
      Agreement.destroy_all
      Milestone.destroy_all
      Project.destroy_all
      User.destroy_all
    else
      puts "Database has existing data. Skipping seeding. Set FORCE_SEED=true to override."
      exit 0
    end
  end

  # Helper method to create users with predictable data
  def create_user(first_name, last_name, index)
    user = User.create!(
      email: "#{first_name.downcase}.#{last_name.downcase}@flukebase.me",
      password: 'password123',
      password_confirmation: 'password123',
      first_name: first_name,
      last_name: last_name
    )
    user
  end

  # Brazilian and American names
  brazilian_first_names = %w[
    Ana Bruno Carla Diego Elena Felipe Gabriela Hugo Isabella João
    Larissa Mateus Natália Pedro Rafaela Thiago Valentina Xavier Yasmin Zeca
    Adriana Bernardo Camila Danilo Eduarda Fabio Giovanna Henrique Isadora Julio
  ]

  american_first_names = %w[
    Alex Blake Casey Dylan Emma Frank Grace Harper Ian Jessica
    Kyle Luna Mason Nova Oliver Parker Quinn Riley Sam Taylor
    Avery Blake Cameron Drew Ellis Finley Gray Hunter Indigo Jordan
  ]

  brazilian_last_names = %w[
    Silva Santos Oliveira Souza Rodrigues Ferreira Alves Pereira Lima Costa
    Gomes Martins Araújo Melo Barbosa Ribeiro Almeida Monteiro Cardoso Carvalho
  ]

  american_last_names = %w[
    Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez
    Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin
  ]

  # Web3/Startup project ideas
  web3_projects = [
    { name: "DeFi Yield Optimizer", desc: "AI-powered yield farming protocol that automatically optimizes returns across multiple DeFi platforms", stage: Project::PROTOTYPE },
    { name: "Carbon Credit DAO", desc: "Decentralized marketplace for verified carbon credits with transparent tracking on blockchain", stage: Project::IDEA },
    { name: "NFT Creator Studio", desc: "No-code platform for artists to create, mint, and sell NFTs with built-in royalty management", stage: Project::LAUNCHED },
    { name: "Web3 Social Network", desc: "Decentralized social platform where users own their data and earn tokens for quality content", stage: Project::SCALING },
    { name: "ReFi Impact Tracker", desc: "Regenerative finance platform tracking environmental and social impact of investments", stage: Project::PROTOTYPE },
    { name: "DAO Governance Tools", desc: "Suite of tools for managing decentralized organizations with voting, treasury, and proposal systems", stage: Project::LAUNCHED },
    { name: "Crypto Education Platform", desc: "Gamified learning platform teaching blockchain development with hands-on coding challenges", stage: Project::IDEA },
    { name: "Green Energy Trading", desc: "P2P renewable energy trading platform using smart contracts and IoT sensors", stage: Project::PROTOTYPE },
    { name: "Decentralized Identity", desc: "Self-sovereign identity solution for Web3 applications with privacy-preserving verification", stage: Project::SCALING },
    { name: "AI-Powered DeFi Bot", desc: "Intelligent trading bot that learns from market patterns to optimize DeFi strategies", stage: Project::LAUNCHED }
  ]

  web2_projects = [
    { name: "HealthTech Analytics", desc: "AI-driven healthcare analytics platform for personalized treatment recommendations", stage: Project::PROTOTYPE },
    { name: "Sustainable Supply Chain", desc: "End-to-end supply chain transparency platform for ethical sourcing and sustainability", stage: Project::LAUNCHED },
    { name: "EdTech Microlearning", desc: "Bite-sized learning platform with adaptive AI for professional skill development", stage: Project::IDEA },
    { name: "Mental Health Companion", desc: "AI-powered mental health support app with mood tracking and personalized interventions", stage: Project::SCALING },
    { name: "Smart City IoT Platform", desc: "Integrated IoT platform for smart city infrastructure management and optimization", stage: Project::PROTOTYPE },
    { name: "Fintech for SMEs", desc: "Comprehensive financial management platform tailored for small and medium enterprises", stage: Project::LAUNCHED },
    { name: "AgTech Precision Farming", desc: "Precision agriculture platform using drones and AI for crop optimization", stage: Project::IDEA },
    { name: "Remote Work Hub", desc: "All-in-one platform for remote team collaboration with virtual office spaces", stage: Project::SCALING },
    { name: "Elderly Care Tech", desc: "Technology platform connecting elderly with caregivers and family members", stage: Project::PROTOTYPE },
    { name: "Renewable Energy Optimizer", desc: "Smart grid optimization platform for renewable energy distribution", stage: Project::LAUNCHED }
  ]

  all_projects = web3_projects + web2_projects

  # Create predictable test users first
  users = []
  puts "Creating predictable test users..."

  # Primary test users with known scenarios
  test_users = [
    { first: "Alice", last: "Entrepreneur", desc: "Project owner with multiple agreements" },
    { first: "Bob", last: "Mentor", desc: "Active mentor with many projects" },
    { first: "Carol", last: "Cofounder", desc: "Serial co-founder" },
    { first: "Dave", last: "Hybrid", desc: "Experienced user with projects and collaborations" },
    { first: "Emma", last: "Expert", desc: "Experienced collaborator and project creator" },
    { first: "Frank", last: "Newbie", desc: "New user, no agreements yet" },
    { first: "Grace", last: "Superuser", desc: "Active community member" },
    { first: "Henry", last: "Overdue", desc: "Has overdue agreements" },
    { first: "Ivy", last: "Completed", desc: "Only completed agreements" },
    { first: "Jack", last: "Pending", desc: "Only pending agreements" }
  ]

  test_users.each_with_index do |user_data, i|
    user = create_user(user_data[:first], user_data[:last], i)
    users << user
    puts "  Created #{user.full_name} (#{user_data[:desc]})"
  end

  # Add more random users to reach 55 total
  puts "Creating additional random users..."
  (55 - test_users.length).times do |i|
    idx = i + test_users.length
    is_brazilian = idx.even?
    first_name = is_brazilian ? brazilian_first_names.sample : american_first_names.sample
    last_name = is_brazilian ? brazilian_last_names.sample : american_last_names.sample

    user = User.create!(
      email: "user#{idx+1}@flukebase.me",
      password: 'password123',
      password_confirmation: 'password123',
      first_name: first_name,
      last_name: last_name
    )

    # Note: Role system removed - all users are community members

    users << user
  end

  puts "Creating projects and milestones..."
  projects = []

  # Each user creates 1-3 projects
  users.each do |user|
    project_count = rand(1..3)
    project_count.times do
      project_data = all_projects.sample

      # Note: public_fields will be set to default essential fields automatically
      # (name, description, stage, collaboration_type, category, funding_status, team_size)
      project = Project.create!(
        name: project_data[:name],
        description: project_data[:desc],
        stage: project_data[:stage],
        user: user,
        collaboration_type: [ Project::SEEKING_MENTOR, Project::SEEKING_COFOUNDER, Project::SEEKING_BOTH ].sample,
        category: [ 'FinTech', 'HealthTech', 'EdTech', 'Web3', 'DeFi', 'NFT', 'DAO', 'ReFi', 'AgTech', 'CleanTech' ].sample,
        target_market: [ 'B2B', 'B2C', 'B2B2C' ].sample,
        funding_status: [ 'Pre-seed', 'Seed', 'Series A', 'Bootstrapped' ].sample,
        team_size: rand(1..15)
      )

      projects << project

      # Create 3-6 milestones per project based on stage
      milestone_templates = case project.stage
      when Project::IDEA
        [
          "Market research and validation",
          "Define MVP requirements",
          "Create user personas",
          "Competitive analysis",
          "Technical feasibility study",
          "Initial prototype wireframes"
        ]
      when Project::PROTOTYPE
        [
          "Complete MVP development",
          "User testing with 20 beta users",
          "Iterate based on feedback",
          "Secure initial funding",
          "Build core team",
          "Prepare for launch"
        ]
      when Project::LAUNCHED
        [
          "Achieve 1000 active users",
          "Implement analytics tracking",
          "Customer acquisition optimization",
          "Revenue model validation",
          "Scale infrastructure",
          "Prepare Series A pitch"
        ]
      when Project::SCALING
        [
          "Expand to new markets",
          "Hire senior leadership team",
          "Implement advanced features",
          "Achieve profitability",
          "Strategic partnerships",
          "International expansion"
        ]
      end

      rand(3..6).times do
        Milestone.create!(
          title: milestone_templates.sample,
          description: Faker::Lorem.paragraph(sentence_count: 2),
          due_date: rand(1..120).days.from_now,
          status: [ Milestone::NOT_STARTED, Milestone::IN_PROGRESS, Milestone::COMPLETED ].sample,
          project: project
        )
      end
    end
  end

  puts "Creating agreements with predictable scenarios..."
  agreements = []

  # Get our test users for predictable scenarios
  alice = users.find { |u| u.first_name == "Alice" }  # Entrepreneur
  bob = users.find { |u| u.first_name == "Bob" }      # Mentor
  carol = users.find { |u| u.first_name == "Carol" }  # Cofounder
  henry = users.find { |u| u.first_name == "Henry" }  # Overdue
  ivy = users.find { |u| u.first_name == "Ivy" }      # Completed
  jack = users.find { |u| u.first_name == "Jack" }    # Pending

  # Helper to create agreements
  def create_agreement(project, partner, agreement_type, status, start_offset_days = 0, duration_weeks = 26, hours_per_week = 10)
    start_date = start_offset_days.days.ago
    end_date = start_date + duration_weeks.weeks

    agreement = Agreement.create!(
      project: project,
      agreement_type: agreement_type,
      status: status,
      start_date: start_date,
      end_date: end_date,
      terms: agreement_type == Agreement::MENTORSHIP ?
        "Weekly mentoring sessions, strategic guidance, and industry connections" :
        "Equal partnership with shared responsibilities and equity split",
      payment_type: Agreement::HYBRID,
      tasks: agreement_type == Agreement::MENTORSHIP ?
        "Product strategy, market analysis, fundraising guidance, team building advice" :
        "Product development, business operations, fundraising, team management",
      weekly_hours: hours_per_week,
      hourly_rate: rand(75..150),
      equity_percentage: agreement_type == Agreement::CO_FOUNDER ? rand(10..30) : rand(1..5),
      milestone_ids: project.milestones.sample(rand(1..2)).pluck(:id)
    )

    # Create agreement participants
    AgreementParticipant.create!(
      agreement: agreement,
      user: project.user,
      user_role: 'entrepreneur',
      project: project,
      is_initiator: true,
      accept_or_counter_turn_id: partner.id
    )

    AgreementParticipant.create!(
      agreement: agreement,
      user: partner,
      user_role: agreement_type == Agreement::MENTORSHIP ? 'mentor' : 'co_founder',
      project: project,
      is_initiator: false,
      accept_or_counter_turn_id: partner.id
    )

    agreement
  end

  # Create specific test scenarios for Alice's project (first project)
  alice_project = projects.find { |p| p.user == alice }
  if alice_project
    puts "  Creating test agreements for #{alice.full_name}'s project..."

    # 1. Active mentorship with lots of time logged
    agreements << create_agreement(alice_project, bob, Agreement::MENTORSHIP, Agreement::ACCEPTED, 30, 40, 15)

    # 2. Completed co-founder agreement
    agreements << create_agreement(alice_project, carol, Agreement::CO_FOUNDER, Agreement::COMPLETED, 90, 20, 25)

    # 3. Overdue mentorship (started but past end date)
    agreements << create_agreement(alice_project, henry, Agreement::MENTORSHIP, Agreement::ACCEPTED, 60, 8, 12)

    # 4. Pending agreement (not started yet)
    agreements << create_agreement(alice_project, jack, Agreement::MENTORSHIP, Agreement::PENDING, -7, 26, 8)

    # 5. Recently completed with perfect time tracking
    agreements << create_agreement(alice_project, ivy, Agreement::MENTORSHIP, Agreement::COMPLETED, 45, 12, 10)
  end

  # Create random agreements for other projects
  remaining_projects = projects.reject { |p| p == alice_project }
  remaining_projects.each do |project|
    agreement_count = rand(2..5)  # Fewer random agreements
    potential_partners = users.reject { |u| u == project.user }

    agreement_count.times do
      partner = potential_partners.sample
      next if partner.nil?

      agreement_type = [ Agreement::MENTORSHIP, Agreement::CO_FOUNDER ].sample
      status = [ Agreement::PENDING, Agreement::ACCEPTED, Agreement::COMPLETED ].sample

      agreements << create_agreement(
        project,
        partner,
        agreement_type,
        status,
        rand(-30..30),      # start_offset_days
        rand(12..52),       # duration_weeks
        agreement_type == Agreement::MENTORSHIP ? rand(5..15) : rand(20..40)  # hours_per_week
      )
    end
  end

  puts "Creating realistic time logs..."

  # Helper to create realistic time logs for an agreement
  def create_time_logs_for_agreement(agreement, intensity = :normal)
    return unless agreement.status == Agreement::ACCEPTED || agreement.status == Agreement::COMPLETED

    # Determine who logs time (typically the non-project-owner)
    working_user = agreement.other_party || agreement.initiator
    return unless working_user

    # Calculate realistic time logging based on agreement duration
    weeks_active = if agreement.completed?
      ((agreement.updated_at.to_date - agreement.start_date) / 7).ceil
    else
      [ ((Date.current - agreement.start_date) / 7).ceil, 0 ].max
    end

    return if weeks_active <= 0

    # Determine hours to log based on intensity
    target_hours = case intensity
    when :heavy
      (agreement.weekly_hours * weeks_active * 1.1).round  # 110% of target
    when :perfect
      (agreement.weekly_hours * weeks_active).round        # Exactly as agreed
    when :light
      (agreement.weekly_hours * weeks_active * 0.7).round  # 70% of target
    when :none
      0
    else
      (agreement.weekly_hours * weeks_active * rand(0.8..1.2)).round  # 80-120% variance
    end

    return if target_hours <= 0

    # Create realistic time entries
    logged_hours = 0
    current_date = agreement.start_date

    while logged_hours < target_hours && current_date <= Date.current
      # Skip weekends for most entries (80% skip rate)
      if current_date.saturday? || current_date.sunday?
        if rand < 0.8
          current_date += 1.day
          next
        end
      end

      # Randomly skip some days
      if rand < 0.3
        current_date += 1.day
        next
      end

      # Random session length (1-8 hours, weighted toward 2-4 hours)
      remaining_hours = target_hours - logged_hours
      session_hours = [ rand(1..8), remaining_hours ].min
      session_hours = [ session_hours, rand(2..4) ].min if rand < 0.6  # Weight toward shorter sessions

      # Ensure start_time is in the past (at least 1 hour ago)
      max_start_time = [ Time.current - 1.hour, current_date.end_of_day ].min
      start_time = [ current_date.beginning_of_day + rand(9..17).hours + rand(0..59).minutes, max_start_time ].min
      end_time = start_time + session_hours.hours

      TimeLog.create!(
        project: agreement.project,
        user: working_user,
        milestone: agreement.selected_milestones.sample || agreement.project.milestones.sample,
        started_at: start_time,
        ended_at: end_time,
        hours_spent: session_hours,
        description: [
          "Working on user interface improvements",
          "Backend API development",
          "Market research and analysis",
          "Customer interviews and feedback",
          "Technical architecture planning",
          "Database optimization",
          "Testing and bug fixes",
          "Documentation updates",
          "Team coordination meeting",
          "Investor pitch preparation",
          "Code review and refactoring",
          "Performance optimization",
          "Feature development",
          "Bug investigation and fixes"
        ].sample,
        status: "completed",
        manual_entry: rand < 0.3  # 30% manual entries
      )

      logged_hours += session_hours
      current_date += rand(1..3).days  # Variable gaps between sessions
    end

    puts "    Created #{TimeLog.where(project: agreement.project, user: working_user).count} time logs for #{working_user.full_name} (#{logged_hours}h total)"
  end

  # Create predictable time logs for test scenarios
  if alice_project
    alice_agreements = agreements.select { |a| a.project == alice_project }

    alice_agreements.each do |agreement|
      intensity = case agreement.other_party&.first_name
      when "Bob"    # Active mentor - lots of time
        :heavy
      when "Carol"  # Completed co-founder - perfect tracking
        :perfect
      when "Henry"  # Overdue mentor - light work
        :light
      when "Jack"   # Pending - no time yet
        :none
      when "Ivy"    # Completed mentor - perfect tracking
        :perfect
      else
        :normal
      end

      create_time_logs_for_agreement(agreement, intensity)
    end
  end

  # Create time logs for other agreements
  remaining_agreements = agreements.reject { |a| a.project == alice_project }
  remaining_agreements.each do |agreement|
    create_time_logs_for_agreement(agreement, :normal)
  end

  puts "Creating conversations and messages..."

  # Create conversations between agreement participants
  agreements.each do |agreement|
    next unless agreement.initiator && agreement.other_party

    conversation = Conversation.between(agreement.initiator.id, agreement.other_party.id)

    # Create 3-10 messages per conversation
    rand(3..10).times do |i|
      sender = i.even? ? conversation.sender : conversation.recipient

      message_templates = [
        "Hey! I've been working on the #{agreement.project.name} project. What do you think about our progress?",
        "Great work on the latest milestone! The results look promising.",
        "I have some ideas for improving our approach. Can we schedule a call?",
        "The market feedback has been positive. Let's discuss next steps.",
        "I've completed the tasks we discussed. Ready for your review.",
        "Found an interesting opportunity that might be relevant to our project.",
        "The technical implementation is going well. Any concerns on your end?",
        "Let's sync up on the timeline. Are we still on track for the deadline?",
        "I've updated the project documentation. Please take a look when you can.",
        "Excited about the progress we're making together!"
      ]

      Message.create!(
        conversation: conversation,
        user: sender,
        body: message_templates.sample,
        read: [ true, false ].sample,
        created_at: rand(30.days.ago..Time.current)
      )
    end
  end

  puts "Creating meetings..."

  # Create meetings for accepted agreements
  agreements.select { |a| a.status == Agreement::ACCEPTED }.each do |agreement|
    rand(2..5).times do
      start_time = rand(7.days.ago..30.days.from_now).change(hour: rand(9..17))

      Meeting.create!(
        agreement: agreement,
        title: [
          "Weekly Progress Review",
          "Strategic Planning Session",
          "Technical Architecture Discussion",
          "Market Analysis Review",
          "Investor Pitch Preparation",
          "Team Coordination Meeting",
          "Product Roadmap Planning",
          "Customer Feedback Review",
          "Milestone Planning Session",
          "Partnership Discussion"
        ].sample,
        description: Faker::Lorem.paragraph(sentence_count: 2),
        start_time: start_time,
        end_time: start_time + [ 1, 1.5, 2 ].sample.hours
      )
    end
  end

  puts "\n✅ Enhanced demo seed data created successfully!"
  puts "📊 Summary:"
  puts "   👥 Users: #{User.count}"
  puts "   🚀 Projects: #{Project.count}"
  puts "   📋 Agreements: #{Agreement.count}"
  puts "   🎯 Milestones: #{Milestone.count}"
  puts "   ⏰ Time Logs: #{TimeLog.count}"
  puts "   💬 Messages: #{Message.count}"
  puts "   📅 Meetings: #{Meeting.count}"

  puts "\n🧪 Test User Scenarios Created:"
  puts "   • alice.entrepreneur@flukebase.me - Project owner with multiple agreement types"
  puts "   • bob.mentor@flukebase.me - Active mentor with heavy time logging"
  puts "   • carol.cofounder@flukebase.me - Completed co-founder with perfect tracking"
  puts "   • henry.overdue@flukebase.me - Mentor with overdue agreement"
  puts "   • ivy.completed@flukebase.me - Mentor with completed agreement"
  puts "   • jack.pending@flukebase.me - Mentor with pending agreement"
  puts "   • frank.newbie@flukebase.me - New entrepreneur with no agreements"
  puts "   • grace.superuser@flukebase.me - User with all roles"

  puts "\n🎯 Key Test Cases:"
  puts "   📈 Time tracking: Realistic patterns with weekday bias"
  puts "   📅 Agreement lifecycle: Pending → Accepted → Completed"
  puts "   ⏰ Overdue scenarios: Past end dates with varying completion"
  puts "   💯 Perfect tracking: Agreements with exactly committed hours"
  puts "   🚀 Heavy usage: Over-committed mentors and active projects"
  puts "   📊 Mixed intensities: Light, normal, and heavy time logging"

  puts "\n🔑 Login with any test user using password: 'password123'"
  puts "\n🎉 Ready to test Flukebase with predictable scenarios!"
end
