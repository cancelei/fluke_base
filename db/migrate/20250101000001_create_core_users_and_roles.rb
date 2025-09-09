class CreateCoreUsersAndRoles < ActiveRecord::Migration[8.0]
  def change
    # Enable PostgreSQL extensions
    enable_extension 'plpgsql'

    # Devise users table
    create_table :users do |t|
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      # Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      # Rememberable
      t.datetime :remember_created_at

      # Basic profile
      t.string :first_name, null: false
      t.string :last_name, null: false

      # Onboarding and profile fields
      t.boolean :onboarded, default: false
      t.text :bio
      t.string :avatar

      # Business profile
      t.float :years_of_experience
      t.float :hourly_rate
      t.string :industries, array: true, default: []
      t.string :skills, array: true, default: []
      t.string :business_stage
      t.string :help_seekings, array: true, default: []
      t.text :business_info

      # Social media links
      t.string :linkedin
      t.string :x
      t.string :youtube
      t.string :facebook
      t.string :tiktok

      # GitHub integration
      t.string :github_username
      t.string :github_token, limit: 255

      # UI preferences
      t.boolean :show_project_context_nav, default: false, null: false

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true

    # Roles table
    create_table :roles do |t|
      t.string :name, null: false
      t.timestamps null: false
    end

    add_index :roles, "lower(name)", unique: true, name: "index_roles_on_lower_name"

    # User roles junction table
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.boolean :onboarded, default: false
      t.timestamps null: false
    end

    # Add foreign key references to users table
    add_reference :users, :current_role, foreign_key: { to_table: :roles }
  end
end
