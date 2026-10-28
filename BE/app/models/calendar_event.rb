class CalendarEvent < ApplicationRecord
  SOURCES = %w[local google_calendar].freeze

  belongs_to :user

  validates :title, presence: true, length: { maximum: 255 }
  validates :start_at, presence: true
  validates :source, inclusion: { in: SOURCES }
  validate :end_after_start

  scope :local, -> { where(source: "local") }
  scope :from_google, -> { where(source: "google_calendar") }
  scope :chronological, -> { order(:start_at) }
  scope :between, lambda { |from, to|
    scope = all
    scope = scope.where(start_at: from..) if from.present?
    scope = scope.where(start_at: ..to) if to.present?
    scope
  }

  private

  def end_after_start
    return if end_at.blank? || start_at.blank? || end_at >= start_at

    errors.add(:end_at, :before_start)
  end
end
