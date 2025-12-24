# == Schema Information
#
# Table name: notifications
#
#  id         :bigint           not null, primary key
#  message    :text             not null
#  read_at    :datetime
#  title      :string           not null
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_notifications_on_created_at           (created_at)
#  index_notifications_on_read_at              (read_at)
#  index_notifications_on_user_id              (user_id)
#  index_notifications_on_user_id_and_read_at  (user_id,read_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Notification < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :message, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(10) }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update(read_at: Time.current)
  end
end
