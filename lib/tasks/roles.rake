namespace :roles do
  desc "Ensure default roles exist"
  task create_default: :environment do
    Role.ensure_default_roles_exist
    puts "Default roles created: #{Role.all.pluck(:name).join(', ')}"
  end
end
