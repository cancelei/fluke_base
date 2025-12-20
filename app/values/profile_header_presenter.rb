# frozen_string_literal: true

# Value object for profile header presentation
ProfileHeaderPresenter = Data.define(
  :display_name,
  :badges,
  :formatted_bio,
  :member_since,
  :projects_count,
  :agreements_count
)
