# frozen_string_literal: true

module Github
  # Resolves GitHub commit authors to FlukeBase users
  #
  # Maps commits to users by:
  # 1. Email address matching
  # 2. GitHub username matching
  #
  # Usage:
  #   resolver = Github::UserResolver.new(project)
  #   user_id = resolver.find_user_id("user@example.com", commit)
  #
  class UserResolver
    attr_reader :project, :user_emails, :user_github_identifiers, :agreements

    # Initialize the resolver and preload user mappings
    # @param project [Project] The project to resolve users for
    def initialize(project)
      @project = project
      load_users
    end

    # Find user ID by email or GitHub username
    # @param author_identifier [String] Email or GitHub username
    # @param commit [Sawyer::Resource, nil] Optional commit object with GitHub author info
    # @return [Integer, nil] User ID if found, nil otherwise
    def find_user_id(author_identifier, commit = nil)
      return nil if author_identifier.blank?

      identifier = author_identifier.to_s.downcase

      # Try email lookup first
      user_id = user_emails[identifier]
      return user_id if user_id

      # Try GitHub login from commit
      if commit&.author&.login
        user_id = user_github_identifiers[commit.author.login.downcase]
        return user_id if user_id
      end

      # Try identifier as GitHub username
      user_id = user_github_identifiers[identifier]
      return user_id if user_id

      nil
    end

    # Find user by GitHub identifier (username or email)
    # @param identifier [String] GitHub username or email
    # @return [User, nil] User if found
    def find_user(identifier)
      user_id = find_user_id(identifier)
      User.find_by(id: user_id) if user_id
    end

    # Check if an identifier maps to a registered user
    # @param identifier [String] Email or GitHub username
    # @return [Boolean]
    def registered_user?(identifier)
      find_user_id(identifier).present?
    end

    private

    # Preload user mappings for efficient lookups
    def load_users
      @agreements = project.agreements.active.includes(agreement_participants: :user)

      # Collect all related users
      agreement_users = agreements.flat_map { |agreement| agreement.agreement_participants.map(&:user) }
      related_users = ([project.user] + agreement_users).compact.uniq

      # Build lookup hashes
      @user_emails = {}
      @user_github_identifiers = {}

      User.where(id: related_users.map(&:id)).find_each do |user|
        # Map email
        @user_emails[user.email.downcase] = user.id if user.email.present?

        # Map GitHub username
        if user.github_username.present?
          @user_github_identifiers[user.github_username.downcase] = user.id
        end
      end
    end
  end
end
