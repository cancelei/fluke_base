# This initializer adds missing presence validators to models
# as identified by active_record_doctor

Rails.application.config.after_initialize do
  # Only run in development mode to avoid performance impact in production
  if Rails.env.development?
    # Add presence validators to ActiveStorage models
    if defined?(ActiveStorage::Attachment)
      ActiveStorage::Attachment.class_eval do
        validates :name, presence: true, if: -> { !new_record? || name.present? }
        validates :record_type, presence: true, if: -> { !new_record? || record_type.present? }
      end
    end

    if defined?(ActiveStorage::Blob)
      ActiveStorage::Blob.class_eval do
        validates :key, presence: true, if: -> { !new_record? || key.present? }
        validates :filename, presence: true, if: -> { !new_record? || filename.present? }
        validates :byte_size, presence: true, if: -> { !new_record? || byte_size.present? }
      end
    end

    if defined?(ActiveStorage::VariantRecord)
      ActiveStorage::VariantRecord.class_eval do
        validates :variation_digest, presence: true, if: -> { !new_record? || variation_digest.present? }
      end
    end

    # Add presence validators to Project model
    if defined?(Project)
      Project.class_eval do
        validates :public_fields, presence: true, if: -> { !new_record? || public_fields.present? }
      end
    end

    # Add presence validators to SolidCable models
    if defined?(SolidCable::Message)
      SolidCable::Message.class_eval do
        validates :channel, presence: true, if: -> { !new_record? || channel.present? }
        validates :payload, presence: true, if: -> { !new_record? || payload.present? }
        validates :channel_hash, presence: true, if: -> { !new_record? || channel_hash.present? }
      end
    end

    # Add presence validators to SolidQueue models
    if defined?(SolidQueue::BlockedExecution)
      SolidQueue::BlockedExecution.class_eval do
        validates :queue_name, presence: true, if: -> { !new_record? || queue_name.present? }
        validates :priority, presence: true, if: -> { !new_record? || priority.present? }
        validates :concurrency_key, presence: true, if: -> { !new_record? || concurrency_key.present? }
        validates :expires_at, presence: true, if: -> { !new_record? || expires_at.present? }
      end
    end

    if defined?(SolidQueue::Job)
      SolidQueue::Job.class_eval do
        validates :queue_name, presence: true, if: -> { !new_record? || queue_name.present? }
        validates :class_name, presence: true, if: -> { !new_record? || class_name.present? }
        validates :priority, presence: true, if: -> { !new_record? || priority.present? }
      end
    end

    if defined?(SolidQueue::Pause)
      SolidQueue::Pause.class_eval do
        validates :queue_name, presence: true, if: -> { !new_record? || queue_name.present? }
      end
    end

    if defined?(SolidQueue::Process)
      SolidQueue::Process.class_eval do
        validates :kind, presence: true, if: -> { !new_record? || kind.present? }
        validates :last_heartbeat_at, presence: true, if: -> { !new_record? || last_heartbeat_at.present? }
        validates :pid, presence: true, if: -> { !new_record? || pid.present? }
        validates :name, presence: true, if: -> { !new_record? || name.present? }
      end
    end

    if defined?(SolidQueue::ReadyExecution)
      SolidQueue::ReadyExecution.class_eval do
        validates :queue_name, presence: true, if: -> { !new_record? || queue_name.present? }
        validates :priority, presence: true, if: -> { !new_record? || priority.present? }
      end
    end

    if defined?(SolidQueue::RecurringExecution)
      SolidQueue::RecurringExecution.class_eval do
        validates :task_key, presence: true, if: -> { !new_record? || task_key.present? }
        validates :run_at, presence: true, if: -> { !new_record? || run_at.present? }
      end
    end

    if defined?(SolidQueue::RecurringTask)
      SolidQueue::RecurringTask.class_eval do
        validates :key, presence: true, if: -> { !new_record? || key.present? }
        validates :schedule, presence: true, if: -> { !new_record? || schedule.present? }
        validates :static, presence: true, if: -> { !new_record? || static.present? }
      end
    end

    if defined?(SolidQueue::ScheduledExecution)
      SolidQueue::ScheduledExecution.class_eval do
        validates :queue_name, presence: true, if: -> { !new_record? || queue_name.present? }
        validates :priority, presence: true, if: -> { !new_record? || priority.present? }
        validates :scheduled_at, presence: true, if: -> { !new_record? || scheduled_at.present? }
      end
    end

    if defined?(SolidQueue::Semaphore)
      SolidQueue::Semaphore.class_eval do
        validates :key, presence: true, if: -> { !new_record? || key.present? }
        validates :value, presence: true, if: -> { !new_record? || value.present? }
        validates :expires_at, presence: true, if: -> { !new_record? || expires_at.present? }
      end
    end

    # Add presence validators to User model
    if defined?(User)
      User.class_eval do
        validates :encrypted_password, presence: true, if: -> { !new_record? || encrypted_password.present? }
        validates :show_project_context_nav, presence: true, if: -> { !new_record? || show_project_context_nav.present? }
      end
    end
  end
end
