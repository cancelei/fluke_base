# frozen_string_literal: true

namespace :slugs do
  desc "Regenerate slugs for all existing records (Project, User, Milestone)"
  task regenerate: :environment do
    puts "Regenerating slugs for existing records..."

    # Projects
    project_count = Project.where(slug: nil).count
    puts "Generating slugs for #{project_count} projects..."
    Project.where(slug: nil).find_each do |project|
      project.slug = nil
      project.save(validate: false)
    end
    puts "  Done."

    # Users
    user_count = User.where(slug: nil).count
    puts "Generating slugs for #{user_count} users..."
    User.where(slug: nil).find_each do |user|
      user.slug = nil
      user.save(validate: false)
    end
    puts "  Done."

    # Milestones
    milestone_count = Milestone.where(slug: nil).count
    puts "Generating slugs for #{milestone_count} milestones..."
    Milestone.where(slug: nil).find_each do |milestone|
      milestone.slug = nil
      milestone.save(validate: false)
    end
    puts "  Done."

    puts "Slug regeneration complete!"
  end
end
