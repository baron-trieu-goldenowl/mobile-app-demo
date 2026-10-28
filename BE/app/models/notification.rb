class Notification < ApplicationRecord
  belongs_to :user

  validates :title, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent_first, -> { order(created_at: :desc) }
end
