# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create roles
puts "Creating roles..."
Role.ensure_default_roles_exist

# Only create test users in development
if Rails.env.development?
  puts "Creating test users..."

  # Create admin user
  admin = User.create_with(
    password: 'password',
    password_confirmation: 'password',
    first_name: 'Admin',
    last_name: 'User'
  ).find_or_create_by!(email: 'admin@example.com')

  # Create entrepreneurs
  entrepreneurs = []

  3.times do |i|
    entrepreneur = User.create_with(
      password: 'password',
      password_confirmation: 'password',
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name
    ).find_or_create_by!(email: "entrepreneur#{i+1}@example.com")
    entrepreneur.add_role(Role::ENTREPRENEUR)
    entrepreneurs << entrepreneur
  end

  # Create mentors
  mentors = []

  3.times do |i|
    mentor = User.create_with(
      password: 'password',
      password_confirmation: 'password',
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name
    ).find_or_create_by!(email: "mentor#{i+1}@example.com")
    mentor.add_role(Role::MENTOR)
    mentors << mentor
  end

  # Create a user with all roles
  multi_role = User.create_with(
    password: 'password',
    password_confirmation: 'password',
    first_name: 'Multi',
    last_name: 'Role'
  ).find_or_create_by!(email: "multirole@example.com")
  multi_role.add_role(Role::ENTREPRENEUR)
  multi_role.add_role(Role::MENTOR)
  multi_role.add_role(Role::CO_FOUNDER)

  # Create projects
  puts "Creating projects..."

  project_stages = [ Project::IDEA, Project::PROTOTYPE, Project::LAUNCHED, Project::SCALING ]

  entrepreneurs.each do |entrepreneur|
    3.times do |i|
      project = Project.create!(
        name: Faker::Company.name,
        description: Faker::Company.catch_phrase + ". " + Faker::Company.bs.capitalize,
        stage: project_stages.sample,
        user: entrepreneur
      )

      # Create milestones for each project
      rand(3..5).times do
        Milestone.create!(
          title: [ "Validate customer problem", "Create prototype", "Test with 10 users",
                 "Get first paying customer", "Reach 100 users", "Secure seed funding" ].sample,
          description: Faker::Lorem.paragraph,
          due_date: rand(1..90).days.from_now,
          status: [ Milestone::NOT_STARTED, Milestone::IN_PROGRESS, Milestone::COMPLETED ].sample,
          project: project
        )
      end
    end
  end

  # Create agreements
  puts "Creating agreements..."

  entrepreneurs.each do |entrepreneur|
    projects = entrepreneur.projects.sample(2) # Pick 2 random projects

    projects.each do |project|
      # Create a mentorship agreement
      agreement = Agreement.create!(
        agreement_type: Agreement::MENTORSHIP,
        status: [ Agreement::PENDING, Agreement::ACCEPTED, Agreement::COMPLETED ].sample,
        start_date: Date.today,
        end_date: 3.months.from_now,
        # Agreement participants will be created via AgreementForm
        project: project,
        terms: "Weekly meetings, feedback on product development, introductions to potential customers.",
        payment_type: [ Agreement::HOURLY, Agreement::EQUITY, Agreement::HYBRID ].sample,
        tasks: "Weekly strategy sessions, feedback on product development, market analysis, introductions to potential customers and partners.",
        weekly_hours: rand(5..20),
        hourly_rate: rand(50..200),
        equity_percentage: rand(1..10)
      )

      # Create meetings for each agreement
      if agreement.status == Agreement::ACCEPTED
        rand(2..4).times do |i|
          start_time = rand(1..30).days.from_now.change(hour: rand(9..16))
          Meeting.create!(
            title: [ "Weekly Check-in", "Product Review", "Strategy Session", "Investor Pitch Practice" ].sample,
            description: Faker::Lorem.sentence,
            start_time: start_time,
            end_time: start_time + 1.hour,
            agreement: agreement
          )
        end
      end
    end
  end

  # Create some co-founder agreements for multi-role user
  multi_role_projects = []

  2.times do |i|
    project = Project.create!(
      name: Faker::Company.name,
      description: Faker::Company.catch_phrase + ". " + Faker::Company.bs.capitalize,
      stage: project_stages.sample,
      user: multi_role
    )
    multi_role_projects << project

    # Create milestones
    rand(3..5).times do
      Milestone.create!(
        title: [ "Validate customer problem", "Create prototype", "Test with 10 users",
               "Get first paying customer", "Reach 100 users", "Secure seed funding" ].sample,
        description: Faker::Lorem.paragraph,
        due_date: rand(1..90).days.from_now,
        status: [ Milestone::NOT_STARTED, Milestone::IN_PROGRESS, Milestone::COMPLETED ].sample,
        project: project
      )
    end
  end

  # Create a co-founder agreement
  project = multi_role_projects.first
  agreement = Agreement.create!(
    agreement_type: Agreement::CO_FOUNDER,
    status: Agreement::ACCEPTED,
    start_date: Date.today,
    end_date: 1.year.from_now,
    # Agreement participants will be created via AgreementForm
    project: project,
    terms: "50-50 equity split. Full-time commitment from both parties. Regular progress updates and weekly meetings.",
    payment_type: Agreement::EQUITY,
    tasks: "Product development, business strategy, fundraising, customer acquisition, and team building.",
    weekly_hours: 40,
    hourly_rate: 0,
    equity_percentage: 50
  )

  # Create meetings for co-founder agreement
  3.times do |i|
    start_time = rand(1..30).days.from_now.change(hour: rand(9..16))
    Meeting.create!(
      title: [ "Strategic Planning", "Product Roadmap", "Investor Meeting Prep", "Growth Strategy" ].sample,
      description: Faker::Lorem.sentence,
      start_time: start_time,
      end_time: start_time + 1.hour,
      agreement: agreement
    )
  end

  puts "Seed data created successfully!"
end
