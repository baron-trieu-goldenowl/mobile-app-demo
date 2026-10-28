class User < ApplicationRecord
  EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  PASSWORD_COMPLEXITY = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/

  # Validations are declared below so social sign-in users can exist
  # without a password.
  has_secure_password validations: false

  encrypts :google_refresh_token, :google_access_token

  has_one_attached :avatar

  has_many :identities, dependent: :destroy
  has_many :alarms, dependent: :destroy
  has_many :calendar_events, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :wake_logs, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase.presence }

  validates :email, presence: true, unless: :social_account?
  validates :email, uniqueness: { case_sensitive: false },
                    format: { with: EMAIL_FORMAT },
                    allow_blank: true
  validates :name, length: { maximum: 100 }
  validates :password, presence: true, on: :create, unless: :social_account?
  validates :password, length: { in: 8..72 },
                       format: { with: PASSWORD_COMPLEXITY,
                                 message: :password_complexity },
                       allow_nil: true

  def social_account?
    identities.any?
  end

  def providers
    identities.map(&:provider)
  end

  def google_connected?
    google_refresh_token.present?
  end

  def avatar_url
    return unless avatar.attached?

    Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: false)
  end

  def auth_token
    JsonWebToken.encode({ user_id: id })
  end
end
