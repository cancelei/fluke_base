class AddSchemaConsistencyChanges < ActiveRecord::Migration[8.0]
  def change
    # Fix length inconsistencies between database and model validations

    # The schema limits solid_queue_recurring_tasks.command to 2048 characters
    # but there's no length validator on SolidQueue::RecurringTask.command
    # We'll increase the limit to match the model's expectations
    change_column :solid_queue_recurring_tasks, :command, :text, limit: 10000

    # The length validator on User.github_token enforces a maximum of 255 characters
    # but there's no schema limit on users.github_token
    # We'll add a limit to match the validation
    change_column :users, :github_token, :string, limit: 255
  end
end
