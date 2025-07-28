# Comprehensive Flukebase Demo Seed File
# Creates realistic data for 50-60 active users with Web2/Web3 projects

require 'faker'

# Ensure roles exist
puts "Creating roles..."
Role.ensure_default_roles_exist

# Only create demo data in development
if Rails.env.development?
  puts "🚀 Creating comprehensive demo data..."

  # Clear existing data to avoid conflicts
  puts "Clearing existing data..."
  TimeLog.destroy_all
  Message.destroy_all
  Conversation.destroy_all
  Meeting.destroy_all
  AgreementParticipant.destroy_all
  Agreement.destroy_all
  Milestone.destroy_all
  Project.destroy_all
  UserRole.destroy_all
  User.destroy_all

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

  # Create 55 users with mixed Brazilian and American names
  users = []
  puts "Creating 55 users..."

  55.times do |i|
    is_brazilian = i.even?
    first_name = is_brazilian ? brazilian_first_names.sample : american_first_names.sample
    last_name = is_brazilian ? brazilian_last_names.sample : american_last_names.sample

    user = User.create!(
      email: "user#{i+1}@flukebase.com",
      password: 'password123',
      password_confirmation: 'password123',
      first_name: first_name,
      last_name: last_name
    )

    # Assign roles - most users have multiple roles
    roles = [ Role::ENTREPRENEUR, Role::MENTOR, Role::CO_FOUNDER ].sample(rand(1..3))
    roles.each { |role| user.add_role(role) }

    users << user
  end

  puts "Creating projects and milestones..."
  projects = []

  # Each user creates 1-3 projects
  users.each do |user|
    project_count = rand(1..3)
    project_count.times do
      project_data = all_projects.sample

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

  puts "Creating agreements between users..."
  agreements = []

  # Create 4-8 agreements per project
  projects.each do |project|
    agreement_count = rand(4..8)
    potential_partners = users.reject { |u| u == project.user }

    agreement_count.times do
      partner = potential_partners.sample
      next if partner.nil?

      agreement_type = [ Agreement::MENTORSHIP, Agreement::CO_FOUNDER ].sample

      agreement = Agreement.create!(
        project: project,
        agreement_type: agreement_type,
        status: [ Agreement::PENDING, Agreement::ACCEPTED, Agreement::COMPLETED ].sample,
        start_date: rand(30.days.ago..30.days.from_now),
        end_date: rand(3.months.from_now..1.year.from_now),
        terms: agreement_type == Agreement::MENTORSHIP ?
          "Weekly mentoring sessions, strategic guidance, and industry connections" :
          "Equal partnership with shared responsibilities and equity split",
        payment_type: [ Agreement::HOURLY, Agreement::EQUITY, Agreement::HYBRID ].sample,
        tasks: agreement_type == Agreement::MENTORSHIP ?
          "Product strategy, market analysis, fundraising guidance, team building advice" :
          "Product development, business operations, fundraising, team management",
        weekly_hours: agreement_type == Agreement::MENTORSHIP ? rand(5..15) : rand(20..40),
        hourly_rate: rand(75..250),
        equity_percentage: agreement_type == Agreement::CO_FOUNDER ? rand(10..50) : rand(1..5),
        milestone_ids: project.milestones.sample(rand(1..3)).pluck(:id)
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

      agreements << agreement
    end
  end

  puts "Creating time logs..."

  # Create time logs for accepted agreements
  accepted_agreements = agreements.select { |a| a.status == Agreement::ACCEPTED }

  accepted_agreements.each do |agreement|
    # Create 5-15 time logs per agreement
    rand(5..15).times do
      start_time = rand(30.days.ago..Time.current)
      duration_hours = rand(1..8)
      end_time = start_time + duration_hours.hours

      TimeLog.create!(
        project: agreement.project,
        user: [ agreement.initiator, agreement.other_party ].sample,
        milestone: agreement.selected_milestones.sample,
        started_at: start_time,
        ended_at: end_time,
        hours_spent: duration_hours,
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
          "Investor pitch preparation"
        ].sample,
        status: "completed",
        manual_entry: [ true, false ].sample
      )
    end
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
  accepted_agreements.each do |agreement|
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

  puts "\n✅ Demo seed data created successfully!"
  puts "📊 Summary:"
  puts "   👥 Users: #{User.count}"
  puts "   🚀 Projects: #{Project.count}"
  puts "   📋 Agreements: #{Agreement.count}"
  puts "   🎯 Milestones: #{Milestone.count}"
  puts "   ⏰ Time Logs: #{TimeLog.count}"
  puts "   💬 Messages: #{Message.count}"
  puts "   📅 Meetings: #{Meeting.count}"
  puts "\n🎉 Ready to explore Flukebase with realistic demo data!"
end
