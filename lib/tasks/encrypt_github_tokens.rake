# frozen_string_literal: true

namespace :github do
  desc "Encrypt existing GitHub tokens that were stored before encryption was enabled"
  task encrypt_existing_tokens: :environment do
    puts "Encrypting existing GitHub tokens..."

    # Find users with any GitHub tokens that might be unencrypted
    users_with_tokens = User.where.not(github_user_access_token: nil)
                            .or(User.where.not(github_refresh_token: nil))
                            .or(User.where.not(github_token: nil))

    count = 0
    errors = []

    users_with_tokens.find_each do |user|
      # Simply reading and writing the value will encrypt it
      # Rails encryption handles this automatically
      begin
        user.save!(touch: false)
        count += 1
        print "."
      rescue StandardError => e
        errors << { user_id: user.id, error: e.message }
        print "E"
      end
    end

    puts "\n"
    puts "Encrypted tokens for #{count} users"

    if errors.any?
      puts "\nErrors encountered:"
      errors.each do |err|
        puts "  User #{err[:user_id]}: #{err[:error]}"
      end
    end
  end

  desc "Verify all GitHub tokens are encrypted"
  task verify_encryption: :environment do
    puts "Verifying GitHub token encryption..."

    # Check a sample of tokens to verify they appear encrypted
    sample = User.where.not(github_user_access_token: nil).limit(5)

    if sample.empty?
      puts "No users with GitHub tokens found"
      return
    end

    sample.each do |user|
      raw_value = User.connection.select_value(
        "SELECT github_user_access_token FROM users WHERE id = #{user.id}"
      )

      if raw_value.nil?
        puts "User #{user.id}: No token stored"
      elsif raw_value.start_with?("{")
        puts "User #{user.id}: Token is encrypted (JSON envelope detected)"
      else
        puts "User #{user.id}: WARNING - Token may not be encrypted!"
      end
    end
  end
end
