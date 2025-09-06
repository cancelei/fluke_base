class AddMissingUniqueIndexes < ActiveRecord::Migration[8.0]
  def up
    # Add unique index on conversations(recipient_id, sender_id) if it doesn't exist
    # This prevents duplicate conversations between the same users
    unless index_exists?(:conversations, [ :recipient_id, :sender_id ], name: 'index_conversations_on_recipient_and_sender')
      add_index :conversations, [ :recipient_id, :sender_id ], unique: true, name: 'index_conversations_on_recipient_and_sender'
    end

    # Add unique index on github_logs(commit_sha) if it doesn't exist
    # This ensures each commit is only recorded once
    unless index_exists?(:github_logs, :commit_sha, name: 'index_github_logs_on_commit_sha')
      add_index :github_logs, :commit_sha, unique: true, name: 'index_github_logs_on_commit_sha'
    end

    # Add case-insensitive unique index on roles(name) if it doesn't exist
    # This prevents duplicate roles with different case
    if supports_expression_index?
      # Check if the expression index already exists
      index_exists = connection.execute(<<-SQL).any?
        SELECT 1 FROM pg_indexes#{' '}
        WHERE tablename = 'roles' AND indexname = 'index_roles_on_lower_name'
      SQL

      unless index_exists
        execute <<-SQL
          CREATE UNIQUE INDEX index_roles_on_lower_name ON roles (lower(name));
        SQL
      end
    else
      # Fallback for databases that don't support expression indexes
      unless index_exists?(:roles, :name, name: 'index_roles_on_name')
        add_index :roles, :name, unique: true, name: 'index_roles_on_name'
      end
    end
  end

  def down
    # Remove indexes if they exist
    remove_index :conversations, name: 'index_conversations_on_recipient_and_sender' if index_exists?(:conversations, [ :recipient_id, :sender_id ], name: 'index_conversations_on_recipient_and_sender')
    remove_index :github_logs, name: 'index_github_logs_on_commit_sha' if index_exists?(:github_logs, :commit_sha, name: 'index_github_logs_on_commit_sha')

    if supports_expression_index?
      # Check if the expression index exists
      index_exists = connection.execute(<<-SQL).any?
        SELECT 1 FROM pg_indexes#{' '}
        WHERE tablename = 'roles' AND indexname = 'index_roles_on_lower_name'
      SQL

      if index_exists
        execute <<-SQL
          DROP INDEX index_roles_on_lower_name;
        SQL
      end
    else
      remove_index :roles, name: 'index_roles_on_name' if index_exists?(:roles, :name, name: 'index_roles_on_name')
    end
  end

  private

  def supports_expression_index?
    # PostgreSQL supports expression indexes
    connection.adapter_name.downcase.include?('postgresql')
  end
end
