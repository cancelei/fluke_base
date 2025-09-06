# This initializer fixes model associations based on active_record_doctor recommendations
# It adds proper dependent options to associations for better performance

Rails.application.config.after_initialize do
  # Only run in development mode to avoid performance impact in production
  if Rails.env.development?
    # Fix Agreement associations
    if defined?(Agreement)
      Agreement.class_eval do
        # Use dependent: :delete_all for associations without callbacks
        has_many :agreement_participants, dependent: :delete_all
        has_many :meetings, dependent: :delete_all
        has_many :github_logs, dependent: :delete_all
      end
    end

    # Fix Project associations
    if defined?(Project)
      Project.class_eval do
        # Use dependent: :delete_all for associations without callbacks
        has_many :github_logs, dependent: :delete_all
        has_many :github_branches, dependent: :delete_all
      end
    end

    # Fix Role associations
    if defined?(Role)
      Role.class_eval do
        # Use dependent: :delete_all for associations without callbacks
        has_many :user_roles, dependent: :delete_all
      end
    end

    # Fix SolidQueue::Job associations
    if defined?(SolidQueue::Job)
      SolidQueue::Job.class_eval do
        # Use dependent: :delete for single record associations without callbacks
        belongs_to :recurring_execution, class_name: "SolidQueue::RecurringExecution", optional: true, dependent: :delete
      end
    end

    # Fix User associations
    if defined?(User)
      User.class_eval do
        # Use dependent: :delete_all for associations without callbacks
        has_many :agreement_participants, dependent: :delete_all
        has_many :user_roles, dependent: :delete_all
        has_many :notifications, dependent: :delete_all
      end
    end
  end
end
