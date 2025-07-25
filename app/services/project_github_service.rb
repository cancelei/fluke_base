class ProjectGithubService
  def initialize(project)
    @project = project
  end

  def connected?
    @project.repository_url.present?
  end

  def available_branches
    @project.github_branches.pluck(:id, :branch_name).compact.sort
  end

  def recent_logs(limit = 20)
    @project.github_logs.includes(:user).order(commit_date: :desc).limit(limit)
  end

  def contributions_summary(branch = nil)
    # Get registered users (those who have accounts)
    registered_query = @project.github_logs.joins(:user, :github_branch_logs).where.not(users: { id: nil })
    unregistered_query = @project.github_logs.joins(:github_branch_logs).where(user_id: nil).where.not(unregistered_user_name: [ nil, "" ])

    if branch.present?
      registered_query = registered_query.where(github_branch_logs: { github_branch_id: branch })
      unregistered_query = unregistered_query.where(github_branch_logs: { github_branch_id: branch })
    end

    # Get registered user contributions
    registered_contributions = registered_query
      .select("users.id as user_id, users.first_name, users.last_name, users.github_username,
               COUNT(github_logs.id) as commit_count,
               SUM(github_logs.lines_added) as total_added,
               SUM(github_logs.lines_removed) as total_removed,
               MIN(github_logs.commit_date) as first_commit_date,
               MAX(github_logs.commit_date) as last_commit_date")
      .group("users.id, users.first_name, users.last_name, users.github_username")

    # Get unregistered user contributions
    unregistered_contributions = unregistered_query
      .select("NULL as user_id, github_logs.unregistered_user_name,
               COUNT(github_logs.id) as commit_count,
               SUM(github_logs.lines_added) as total_added,
               SUM(github_logs.lines_removed) as total_removed,
               MIN(github_logs.commit_date) as first_commit_date,
               MAX(github_logs.commit_date) as last_commit_date")
      .group("github_logs.unregistered_user_name")

    # Combine both queries
    all_contributions = registered_contributions.to_a + unregistered_contributions.to_a

    # Format the results
    format_contributions(all_contributions)
  end

  def can_view_logs?(user)
    return false unless user

    # Project owner can always view
    return true if @project.user_id == user.id

    # Check for accepted agreements using AgreementParticipants
    @project.agreements.accepted.joins(:agreement_participants).exists?(agreement_participants: { user_id: user.id })
  end

  def contributions_summary_basic
    @project.github_logs.select("user_id, COUNT(*) as commit_count, SUM(lines_added) as total_added, SUM(lines_removed) as total_removed")
              .group(:user_id)
              .includes(:user)
  end

  def can_access_repository?(user)
    return false if user.nil? || @project.repository_url.blank?
    @project.user_id == user.id ||
    @project.agreements.active.joins(:agreement_participants).exists?(agreement_participants: { user_id: user.id })
  end

  private

  def format_contributions(all_contributions)
    all_contributions.map do |c|
      user = if c.user_id.present?
        User.find(c.user_id)
      else
        # Create a simple object that responds to the methods the view expects
        unregistered_user = OpenStruct.new(
          id: nil,
          name: c.unregistered_user_name,
          github_username: c.unregistered_user_name,
          unregistered: true
        )

        # Define methods needed by the view
        def unregistered_user.avatar_url
          nil
        end

        def unregistered_user.full_name
          name
        end

        def unregistered_user.owner?(_project)
          false
        end

        unregistered_user
      end

      {
        user: user,
        commit_count: c.commit_count.to_i,
        total_added: c.total_added.to_i,
        total_removed: c.total_removed.to_i,
        net_changes: c.total_added.to_i - c.total_removed.to_i,
        first_commit_date: c.first_commit_date,
        last_commit_date: c.last_commit_date
      }
    end
  end
end
