class Notification < ApplicationRecord
  KINDS = %w[general calendar_synced calendar_sync_failed wake_streak].freeze

  belongs_to :user

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS }

  scope :unread, -> { where(read: false) }
  scope :recent_first, -> { order(created_at: :desc) }
end
