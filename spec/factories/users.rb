# == Schema Information
#
# Table name: users
#
#  id                              :bigint           not null, primary key
#  admin                           :boolean          default(FALSE), not null
#  avatar                          :string
#  bio                             :text
#  business_info                   :text
#  business_stage                  :string
#  email                           :string           default(""), not null
#  encrypted_password              :string           default(""), not null
#  facebook                        :string
#  first_name                      :string           not null
#  github_connected_at             :datetime
#  github_refresh_token            :text
#  github_refresh_token_expires_at :datetime
#  github_token                    :text
#  github_token_expires_at         :datetime
#  github_uid                      :string
#  github_user_access_token        :text
#  github_username                 :string
#  help_seekings                   :string           default([]), is an Array
#  hourly_rate                     :float
#  industries                      :string           default([]), is an Array
#  instagram                       :string
#  last_name                       :string           not null
#  linkedin                        :string
#  multi_project_tracking          :boolean          default(FALSE), not null
#  remember_created_at             :datetime
#  reset_password_sent_at          :datetime
#  reset_password_token            :string
#  show_project_context_nav        :boolean          default(FALSE), not null
#  skills                          :string           default([]), is an Array
#  slug                            :string
#  theme_preference                :string           default("nord"), not null
#  tiktok                          :string
#  x                               :string
#  years_of_experience             :float
#  youtube                         :string
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  selected_project_id             :bigint
#
# Indexes
#
#  index_users_on_admin                 (admin)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_github_uid            (github_uid) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_selected_project_id   (selected_project_id)
#  index_users_on_slug                  (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (selected_project_id => projects.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { "John" }
    last_name { "Doe" }

    trait :alice do
      first_name { "Alice" }
      last_name { "Smith" }
      email { "alice.smith@example.com" }
    end

    trait :bob do
      first_name { "Bob" }
      last_name { "Johnson" }
      email { "bob.johnson@example.com" }
      years_of_experience { 10.0 }
    end
  end
end
