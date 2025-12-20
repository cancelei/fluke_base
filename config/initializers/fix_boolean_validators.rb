# This initializer fixes boolean validators based on active_record_doctor recommendations
# It replaces presence validators with inclusion validators for boolean fields

Rails.application.config.after_initialize do
  # Only run in development mode to avoid performance impact in production
  if Rails.env.development?
    # Fix SolidQueue::RecurringTask validators
    if defined?(SolidQueue::RecurringTask)
      SolidQueue::RecurringTask.class_eval do
        # Remove the presence validator for static (boolean field)
        _validators.delete(:static) if _validators[:static].present?
        _validate_callbacks.each do |callback|
          if callback.filter.is_a?(ActiveModel::Validations::PresenceValidator) &&
             callback.filter.attributes.include?(:static)
            skip_callback(:validate, callback.kind, callback.filter)
          end
        end

        # Add inclusion validator instead
        validates :static, inclusion: { in: [true, false] }
      end
    end

    # Fix User validators
    if defined?(User)
      User.class_eval do
        # Remove the presence validator for show_project_context_nav (boolean field)
        _validators.delete(:show_project_context_nav) if _validators[:show_project_context_nav].present?
        _validate_callbacks.each do |callback|
          if callback.filter.is_a?(ActiveModel::Validations::PresenceValidator) &&
             callback.filter.attributes.include?(:show_project_context_nav)
            skip_callback(:validate, callback.kind, callback.filter)
          end
        end

        # Add inclusion validator instead
        validates :show_project_context_nav, inclusion: { in: [true, false] }
      end
    end
  end
end
