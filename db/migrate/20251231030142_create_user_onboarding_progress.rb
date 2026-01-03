class CreateUserOnboardingProgress < ActiveRecord::Migration[8.0]
  def change
    create_table :user_onboarding_progress do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :insights_seen, null: false, default: []  # Array of insight keys
      t.jsonb :milestones_completed, null: false, default: []  # Array of milestone keys
      t.integer :onboarding_stage, null: false, default: 0
      t.datetime :first_ai_session_at
      t.datetime :first_task_completed_at
      t.datetime :onboarding_completed_at
      t.jsonb :preferences, null: false, default: {}  # User preferences for insights

      t.timestamps

      t.index :onboarding_stage
    end
  end
end
