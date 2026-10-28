class WakeLog < ApplicationRecord
  belongs_to :user
  belongs_to :alarm, optional: true

  validates :dismissed_at, presence: true
  validates :snooze_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :mission_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :alarm_belongs_to_user

  scope :since, ->(time) { where(dismissed_at: time..) }
  scope :recent_first, -> { order(dismissed_at: :desc) }

  private

  def alarm_belongs_to_user
    return if alarm.nil? || alarm.user_id == user_id

    errors.add(:alarm, :invalid)
  end
end
