class Alarm < ApplicationRecord
  CHALLENGE_TYPES = %w[none math memory typing shake walk puzzle qr].freeze
  CHALLENGE_DIFFICULTIES = %w[easy medium hard].freeze
  SOUNDS = %w[classic digital chime rising birds].freeze
  TIME_FORMAT = /\A([01]\d|2[0-3]):[0-5]\d\z/

  belongs_to :user
  has_many :wake_logs, dependent: :nullify

  validates :title, presence: true, length: { maximum: 100 }
  validates :time, format: { with: TIME_FORMAT, message: :invalid_time }
  validates :sound, inclusion: { in: SOUNDS }
  validates :challenge_type, inclusion: { in: CHALLENGE_TYPES }
  validates :challenge_difficulty, inclusion: { in: CHALLENGE_DIFFICULTIES }
  validates :volume, numericality: { only_integer: true, in: 0..100 }
  validates :snooze_minutes, numericality: { only_integer: true, in: 0..60 }
  validates :snooze_limit, numericality: { only_integer: true, in: 0..10 }
  validates :qr_code, presence: true, if: :qr_mission?
  validate :repeat_days_are_weekdays

  before_validation :normalize_repeat_days

  scope :chronological, -> { order(:time) }

  def qr_mission?
    challenge_type == "qr"
  end

  private

  def normalize_repeat_days
    self.repeat_days = Array(repeat_days).map(&:to_i).uniq.sort
  end

  def repeat_days_are_weekdays
    return if repeat_days.all? { |day| day.between?(1, 7) }

    errors.add(:repeat_days, :invalid)
  end
end
