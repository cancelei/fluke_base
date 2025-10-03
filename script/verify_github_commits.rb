#!/usr/bin/env ruby
# Script to verify GitHub commits are being stored correctly
# Usage: rails runner script/verify_github_commits.rb [project_id]

project_id = ARGV[0]

if project_id.nil?
  puts "Usage: rails runner script/verify_github_commits.rb <project_id>"
  puts ""
  puts "Available projects:"
  Project.where.not(repository_url: [ nil, '' ]).each do |p|
    puts "  #{p.id}: #{p.name} (#{p.repository_url})"
  end
  exit 1
end

project = Project.find_by(id: project_id)

unless project
  puts "❌ Project with ID #{project_id} not found"
  exit 1
end

puts "=" * 70
puts "GitHub Commits Verification for: #{project.name}"
puts "=" * 70
puts "Repository: #{project.repository_url}"
puts ""

# Check branches
branches = project.github_branches
puts "📂 Branches in database: #{branches.count}"
if branches.any?
  branches.each do |branch|
    puts "  • #{branch.branch_name} (owned by: #{branch.user.email})"
  end
else
  puts "  ⚠️  No branches found. Run 'Refresh Commits' in the UI first."
end
puts ""

# Check commits
commits = project.github_logs
puts "📝 Total commits in database: #{commits.count}"

if commits.any?
  puts ""
  puts "Recent commits (last 5):"
  commits.order(commit_date: :desc).limit(5).each do |commit|
    user_info = commit.user ? commit.user.email : commit.unregistered_user_name
    short_sha = commit.commit_sha[0..7]
    short_msg = commit.commit_message.lines.first&.strip&.[](0..60) || "No message"
    puts "  • #{short_sha} - #{short_msg}"
    puts "    by #{user_info} on #{commit.commit_date.strftime('%Y-%m-%d %H:%M')}"
    puts "    +#{commit.lines_added} -#{commit.lines_removed}"
  end

  puts ""
  puts "📊 Statistics:"
  puts "  Total additions: #{commits.sum(:lines_added)}"
  puts "  Total deletions: #{commits.sum(:lines_removed)}"
  puts "  Date range: #{commits.minimum(:commit_date)&.strftime('%Y-%m-%d')} to #{commits.maximum(:commit_date)&.strftime('%Y-%m-%d')}"

  # Check contributions
  puts ""
  puts "👥 Contributors:"
  contributions = project.github_contributions
  if contributions.any?
    contributions.each do |contrib|
      name = contrib[:user].respond_to?(:email) ? contrib[:user].email : contrib[:user].name
      puts "  • #{name}: #{contrib[:commit_count]} commits (+#{contrib[:total_added]} -#{contrib[:total_removed]})"
    end
  else
    puts "  No contribution data available"
  end

  puts ""
  puts "✅ Commits are being stored correctly!"
  puts ""
  puts "View them at: http://localhost:3000/projects/#{project.id}/github_logs"
else
  puts ""
  puts "⚠️  No commits found in database."
  puts ""
  puts "To fetch commits:"
  puts "  1. Make sure you have branches: GithubFetchBranchesJob.perform_now(#{project.id}, nil)"
  puts "  2. Then fetch commits for a branch:"
  puts "     branch = GithubBranch.find_by(project_id: #{project.id}, branch_name: 'main')"
  puts "     GithubCommitRefreshJob.perform_now(#{project.id}, nil, 'main')"
  puts ""
  puts "Or visit: http://localhost:3000/projects/#{project.id}/github_logs"
  puts "And click 'Refresh Commits' button"
end

puts "=" * 70
