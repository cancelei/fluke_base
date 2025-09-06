class AddMissingForeignKeyIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add missing indexes on foreign keys identified by active_record_doctor

    # Add index on github_logs(project_id)
    add_index :github_logs, :project_id, name: 'index_github_logs_on_project_id', if_not_exists: true

    # Add index on time_logs(milestone_id)
    add_index :time_logs, :milestone_id, name: 'index_time_logs_on_milestone_id', if_not_exists: true

    # Add index on meetings(google_calendar_event_id)
    add_index :meetings, :google_calendar_event_id, name: 'index_meetings_on_google_calendar_event_id', if_not_exists: true

    # Add index on agreement_participants(accept_or_counter_turn_id)
    add_index :agreement_participants, :accept_or_counter_turn_id,
             name: 'index_agreement_participants_on_accept_or_counter_turn_id',
             if_not_exists: true

    # Add index on users(selected_project_id)
    add_index :users, :selected_project_id, name: 'index_users_on_selected_project_id', if_not_exists: true

    # Remove redundant index on conversations(recipient_id)
    remove_index :conversations, name: :index_conversations_on_recipient_id, if_exists: true
  end
end
