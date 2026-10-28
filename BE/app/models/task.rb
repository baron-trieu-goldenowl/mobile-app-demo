class Task < ApplicationRecord
  PRIORITIES = %w[low medium high urgent].freeze
  STATUSES = %w[todo in_progress done].freeze

  belongs_to :user

  validates :title, presence: true, length: { maximum: 255 }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }

  before_save :track_completion, if: :will_save_change_to_status?

  private

  def track_completion
    self.completed_at = status == "done" ? (completed_at || Time.current) : nil
  end
end
